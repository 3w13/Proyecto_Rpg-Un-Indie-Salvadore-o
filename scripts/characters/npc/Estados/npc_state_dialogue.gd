extends NPCStateBase

# NPCStateDialogue
# Estado orientado a ejecutar una conversación con Dialogue Manager.
#
# Flujo general:
# - Al entrar, detiene al NPC y lo deja en animación de espera.
# - Si `auto_start_dialogue` está activo, inicia la conversación automáticamente.
# - Mantiene al NPC inmóvil durante todo el estado.
# - Al finalizar el diálogo, puede cambiar a otro estado configurado.

@export_group("Configuración de Diálogo")

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

# Flag de control para evitar lanzar varias veces el mismo diálogo.
var _dialogue_running: bool = false


# Entrada al estado.
# Prepara al NPC y opcionalmente dispara el diálogo.
func start() -> void:
	print("[NPC Estado] DIALOGUE")
	_stop_npc()
	_play_animation(animation_player_path, ANIMATION_IDLE)

	if auto_start_dialogue:
		trigger_dialogue()


# Salida del estado.
# Limpia la conexión a la señal del diálogo para evitar duplicados.
func end() -> void:
	if _dialogue_manager != null and _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.disconnect(_on_dialogue_ended)
	_dialogue_running = false


# Mientras el estado esté activo, el NPC permanece quieto.
func on_physics_process(_delta: float) -> void:
	_stop_npc()


# Inicia la conversación con el recurso configurado.
# Valida precondiciones (ruta, recurso y singleton) antes de mostrar el balloon.
func trigger_dialogue() -> void:
	print("[Diálogo] Iniciando trigger_dialogue")
	if _dialogue_running:
		print("[Diálogo] Ya hay diálogo en ejecución")
		return

	if dialogue_path == "":
		push_warning("NPCStateDialogue: dialogue_path vacío")
		return

	print("[Diálogo] Cargando recurso: " + dialogue_path)
	_dialogue_resource = load(dialogue_path) as DialogueResource
	if _dialogue_resource == null:
		push_warning("NPCStateDialogue: no se pudo cargar el diálogo -> " + dialogue_path)
		return
	
	print("[Diálogo] Recurso cargado. First title: " + _dialogue_resource.first_title)

	_dialogue_manager = Engine.get_singleton("DialogueManager")
	if _dialogue_manager == null:
		push_warning("NPCStateDialogue: DialogueManager no está disponible")
		return
	
	print("[Diálogo] DialogueManager disponible")

	if not _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

	_dialogue_running = true
	var title_to_use := dialogue_title
	if title_to_use == "":
		title_to_use = _dialogue_resource.first_title
	
	print("[Diálogo] Mostrando balloon con título: " + title_to_use)
	_dialogue_manager.show_dialogue_balloon(_dialogue_resource, title_to_use)


# Al finalizar el diálogo, usa `state_after_dialogue` si está configurado.
# Si no, transiciona al siguiente estado disponible en la máquina de estados.
func _on_dialogue_ended(ended_resource: DialogueResource) -> void:
	if _dialogue_resource == null:
		return
	if ended_resource != _dialogue_resource:
		return

	_dialogue_running = false

	if _dialogue_manager != null and _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.disconnect(_on_dialogue_ended)

	# Si hay estado configurado explícitamente, usarlo.
	if state_after_dialogue != "" and state_machine != null and state_machine.get_node_or_null(state_after_dialogue) != null:
		state_machine.change_to(state_after_dialogue)
		return
	
	# Si no, transicionar al siguiente estado disponible.
	var next_state := _get_next_available_state()
	if next_state != "" and state_machine != null:
		state_machine.change_to(next_state)


# Obtiene el siguiente estado disponible en la máquina de estados (ciclo rotativo).
func _get_next_available_state() -> String:
	if state_machine == null:
		return ""

	var states: Array[NPCStateBase] = []
	for child in state_machine.get_children():
		if child is NPCStateBase:
			states.append(child)

	if states.size() <= 1:
		return ""

	var current_index := states.find(self)
	if current_index == -1:
		return ""

	var next_index := (current_index + 1) % states.size()
	return states[next_index].name
