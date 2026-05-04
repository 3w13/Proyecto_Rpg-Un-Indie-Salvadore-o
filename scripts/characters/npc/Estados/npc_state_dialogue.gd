extends NPCStateBase

signal dialogue_finished

# NPCStateDialogue
# Estado orientado a ejecutar una conversación con Dialogue Manager.
#
# Flujo general:
# - Al entrar, detiene al NPC y lo deja en animación de espera.
# - Si `auto_start_dialogue` está activo, inicia la conversación automáticamente.
# - Mantiene al NPC inmóvil durante todo el estado.
# - Al finalizar el diálogo, puede cambiar a otro estado configurado.

@export_group("Configuración de Diálogo")

# Recurso de diálogo asignable directamente desde el inspector.
# Si está asignado, tiene prioridad sobre `dialogue_path`.
@export var dialogue_resource: DialogueResource

# Ruta del archivo .dialogue que se va a ejecutar.
# Selecciona el archivo de diálogo desde el inspector.
@export_file("*.dialogue") var dialogue_path: String = "res://dialogues/Dialogo_NPC_Simple01.dialogue"

# Título interno del diálogo desde donde iniciar.
# Si se deja vacío, usa `first_title` del recurso.
@export var dialogue_title: String = ""

# Si es true, el diálogo arranca al entrar a este estado.
@export var auto_start_dialogue: bool = true

@export_group("Animación y Estados")

# Nodo del AnimatedSprite2D para animación de espera.
@export var animation_player_path: NodePath = "AnimatedSprite2D"

# Estado opcional al que transicionar cuando termine el diálogo.
@export var state_after_dialogue: String = ""

# Referencia al singleton autoload de Dialogue Manager.
var _dialogue_manager: Node = null

# Recurso de diálogo actualmente cargado/ejecutado por este estado.
var _dialogue_resource: DialogueResource = null

# Indica si este estado tiene un diálogo activo.
var _dialogue_running: bool = false


# Marca este estado como activable solo por interacción explícita.
func _ready() -> void:
	manual_trigger_only = true


# Entrada al estado.
# Prepara al NPC y opcionalmente dispara el diálogo.
func start() -> void:
	print("[NPC Estado] DIALOGUE")
	_stop_npc()
	_play_animation(animation_player_path, ANIMATION_IDLE)
	_bind_dialogue_signals()

	if auto_start_dialogue:
		trigger_dialogue()


# Salida del estado.
# Limpia la conexión a la señal del diálogo para evitar duplicados.
func end() -> void:
	_unbind_dialogue_signals()
	_dialogue_running = false
	_dialogue_resource = null


# Mientras el estado esté activo, el NPC permanece quieto.
func on_physics_process(_delta: float) -> void:
	_stop_npc()


# Inicia la conversación con el recurso configurado.
# Valida precondiciones (ruta, recurso y singleton) antes de mostrar el balloon.
func trigger_dialogue() -> void:
	print("[Diálogo] Iniciando trigger_dialogue")
	if state_machine != null and state_machine.current_state != self:
		return

	if _dialogue_running:
		print("[Diálogo] Ya hay diálogo en ejecución")
		return

	if dialogue_path == "" and dialogue_resource == null:
		push_warning("NPCStateDialogue: no hay diálogo asignado en dialogue_resource ni en dialogue_path")
		return

	_dialogue_resource = _get_configured_dialogue_resource()
	if _dialogue_resource == null:
		push_warning("NPCStateDialogue: no se pudo resolver el diálogo configurado")
		return
	
	print("[Diálogo] Recurso cargado. First title: " + _dialogue_resource.first_title)

	if not _bind_dialogue_signals():
		return
	
	print("[Diálogo] DialogueManager disponible")

	_dialogue_running = true
	var title_to_use := _resolve_dialogue_title()
	if title_to_use == "":
		_dialogue_running = false
		push_warning("NPCStateDialogue: el diálogo no tiene título inicial. Agrega '~ start' al archivo .dialogue o configura dialogue_title en el inspector.")
		return
	
	print("[Diálogo] Mostrando balloon con título: " + title_to_use)
	var dialogue_balloon: Node = _dialogue_manager.show_dialogue_balloon(_dialogue_resource, title_to_use)
	if dialogue_balloon != null:
		if "next_action" in dialogue_balloon:
			dialogue_balloon.next_action = &"interact"
		if "responses_menu" in dialogue_balloon and dialogue_balloon.responses_menu != null and "next_action" in dialogue_balloon.responses_menu:
			dialogue_balloon.responses_menu.next_action = &"interact"


# Al finalizar el diálogo, usa `state_after_dialogue` si está configurado.
# Si no, transiciona al siguiente estado disponible en la máquina de estados.
func _on_dialogue_ended(ended_resource: DialogueResource) -> void:
	if not _dialogue_running:
		return

	if _dialogue_resource == null:
		return
	if ended_resource != _dialogue_resource:
		return

	_dialogue_running = false
	_dialogue_resource = null
	emit_signal("dialogue_finished")
	call_deferred("_transition_after_dialogue")


# Aplica transición de salida al concluir el diálogo.
func _transition_after_dialogue() -> void:
	if state_machine == null:
		return
	if state_machine.current_state != self:
		return

	# Si hay estado configurado explícitamente, usarlo.
	if state_after_dialogue != "" and state_machine != null and state_machine.get_node_or_null(state_after_dialogue) != null:
		state_machine.change_to(state_after_dialogue)
		return
	
	# Si no, transicionar al siguiente estado disponible.
	var next_state := _get_next_available_state()
	if next_state != "" and state_machine != null:
		state_machine.change_to(next_state)


# Obtiene el siguiente estado disponible en la máquina de estados (ciclo rotativo).
# Solo incluye estados que no requieran activación manual (manual_trigger_only = false).
func _get_next_available_state() -> String:
	if state_machine == null:
		return ""

	var states: Array[NPCStateBase] = []
	for child in state_machine.get_children():
		if child is NPCStateBase and not child.manual_trigger_only:
			states.append(child)

	if states.size() <= 1:
		return ""

	var current_index := states.find(self)
	if current_index == -1:
		return ""

	var next_index := (current_index + 1) % states.size()
	return states[next_index].name


# Conecta la señal de finalización del DialogueManager.
func _bind_dialogue_signals() -> bool:
	if _dialogue_manager == null:
		_dialogue_manager = Engine.get_singleton("DialogueManager")
	if _dialogue_manager == null:
		push_warning("NPCStateDialogue: DialogueManager no está disponible")
		return false

	if not _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

	return true


# Desconecta la señal de finalización de diálogo si estaba enlazada.
func _unbind_dialogue_signals() -> void:
	if _dialogue_manager != null and _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.disconnect(_on_dialogue_ended)


# Resuelve el título inicial efectivo del diálogo con fallback a `start`.
func _resolve_dialogue_title() -> String:
	if dialogue_title.strip_edges() != "":
		return dialogue_title.strip_edges()

	if _dialogue_resource != null and _dialogue_resource.first_title.strip_edges() != "":
		return _dialogue_resource.first_title.strip_edges()

	# Fallback común en Dialogue Manager.
	return "start"


# Resuelve el recurso de diálogo desde inspector o desde ruta configurada.
func _get_configured_dialogue_resource() -> DialogueResource:
	if dialogue_resource != null:
		return dialogue_resource

	if dialogue_path.strip_edges() == "":
		return null

	print("[Diálogo] Cargando recurso: " + dialogue_path)
	return load(dialogue_path) as DialogueResource
