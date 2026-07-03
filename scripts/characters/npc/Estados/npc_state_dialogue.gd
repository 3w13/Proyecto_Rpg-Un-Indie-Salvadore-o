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


#region Exportaciones

@export_group("Configuración de Diálogo")

# Recurso de diálogo asignable directamente desde el inspector.
# Si está asignado, tiene prioridad sobre `dialogue_path`.
@export var dialogue_resource: DialogueResource

# Ruta del archivo .dialogue que se va a ejecutar.
@export_file("*.dialogue") var dialogue_path: String = "res://dialogues/Dialogo_NPC_Simple01.dialogue"

# Título interno del diálogo desde donde iniciar.
# Si se deja vacío, usa `first_title` del recurso.
@export var dialogue_title: String = ""

# Si es true, el diálogo arranca automáticamente al entrar a este estado.
@export var auto_start_dialogue: bool = true

# Escena de balloon exclusiva para NPC.
@export_file("*.tscn") var dialogue_balloon_scene_path: String = "res://scenes/ui/Box_Dialogues.tscn"

@export_group("Animación y Estados")

# Nodo del AnimatedSprite2D para la animación de espera.
@export var animation_player_path: NodePath = "AnimatedSprite2D"

# Estado opcional al que transicionar cuando termine el diálogo.
# Si se deja vacío, se usa el siguiente estado disponible en la máquina.
@export var state_after_dialogue: String = ""

#endregion


#region Variables

# Referencia al singleton autoload de Dialogue Manager.
var _dialogue_manager: Node = null

# Recurso de diálogo actualmente cargado/ejecutado por este estado.
var _dialogue_resource: DialogueResource = null

# Indica si este estado tiene un diálogo activo en curso.
var _dialogue_running: bool = false

#endregion


#region Ciclo de vida del estado

# Marca este estado como activable solo por interacción explícita.
func _ready() -> void:
	manual_trigger_only = true


# Al entrar, detiene al NPC, muestra animación de espera y conecta señales.
# Si auto_start_dialogue está activo, inicia la conversación inmediatamente.
func start() -> void:
	print("[NPC Estado] DIALOGUE")
	_stop_npc()
	_play_animation(animation_player_path, ANIMATION_IDLE)
	_bind_dialogue_signals()

	if auto_start_dialogue:
		trigger_dialogue()


# Al salir, desconecta señales y limpia el estado del diálogo.
func end() -> void:
	_unbind_dialogue_signals()
	_dialogue_running = false
	_dialogue_resource = null


# Mientras el estado esté activo, el NPC permanece quieto.
func on_physics_process(_delta: float) -> void:
	_stop_npc()

#endregion


#region Diálogo — API pública

# Inicia la conversación con el recurso configurado.
# Valida precondiciones (ruta, recurso y singleton) antes de mostrar el balloon.
func trigger_dialogue() -> void:
	print("[Diálogo] Iniciando trigger_dialogue")

	# No iniciar si este no es el estado activo.
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
	var dialogue_balloon: Node = _show_dialogue_balloon_for_npc(title_to_use)

	# Configurar la acción de avance del balloon y su menú de respuestas.
	if dialogue_balloon != null:
		if "next_action" in dialogue_balloon:
			dialogue_balloon.next_action = &"interact"
		if "responses_menu" in dialogue_balloon and dialogue_balloon.responses_menu != null and "next_action" in dialogue_balloon.responses_menu:
			dialogue_balloon.responses_menu.next_action = &"interact"

#endregion


#region Diálogo — Transiciones

# Callback al finalizar el diálogo.
# Solo actúa si el recurso que terminó coincide con el que este estado inició.
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


# Aplica la transición de salida al concluir el diálogo.
# Usa state_after_dialogue si está configurado; si no, el siguiente estado disponible.
func _transition_after_dialogue() -> void:
	if state_machine == null:
		return
	if state_machine.current_state != self:
		return

	if state_after_dialogue != "" and state_machine.get_node_or_null(state_after_dialogue) != null:
		state_machine.change_to(state_after_dialogue)
		return

	var next_state := _get_next_available_state()
	if next_state != "" and state_machine != null:
		state_machine.change_to(next_state)


# Recorre los estados hijos de la máquina desde el actual (ciclo rotativo)
# y devuelve el nombre del primero que no requiera activación manual.
func _get_next_available_state() -> String:
	if state_machine == null:
		return ""

	var states := state_machine.get_children()
	var current_index := states.find(self)
	if current_index == -1 or states.size() <= 1:
		return ""

	for offset in range(1, states.size()):
		var next_index := (current_index + offset) % states.size()
		var candidate := states[next_index] as NPCStateBase
		if candidate != null and not candidate.manual_trigger_only:
			return candidate.name

	return ""

#endregion


#region Diálogo — Señales

# Conecta la señal de finalización del DialogueManager.
# Devuelve false si el singleton no está disponible.
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

#endregion


#region Utilidades internas

# Resuelve el título inicial efectivo del diálogo.
# Prioridad: dialogue_title → first_title del recurso → "start" como fallback.
func _resolve_dialogue_title() -> String:
	if dialogue_title.strip_edges() != "":
		return dialogue_title.strip_edges()

	if _dialogue_resource != null and _dialogue_resource.first_title.strip_edges() != "":
		return _dialogue_resource.first_title.strip_edges()

	# Fallback común en Dialogue Manager.
	return "start"


# Resuelve el recurso de diálogo desde el inspector o desde la ruta configurada.
# dialogue_resource tiene prioridad sobre dialogue_path.
func _get_configured_dialogue_resource() -> DialogueResource:
	if dialogue_resource != null:
		return dialogue_resource

	if dialogue_path.strip_edges() == "":
		return null

	print("[Diálogo] Cargando recurso: " + dialogue_path)
	return load(dialogue_path) as DialogueResource


# Muestra el balloon de diálogo para el NPC.
# Si hay una escena de balloon configurada y existe, la usa; si no, usa el balloon por defecto.
func _show_dialogue_balloon_for_npc(title_to_use: String) -> Node:
	var extra_game_states: Array = []
	if controlled_node != null:
		extra_game_states.append(controlled_node)

	if dialogue_balloon_scene_path.strip_edges() != "" and ResourceLoader.exists(dialogue_balloon_scene_path):
		return _dialogue_manager.show_dialogue_balloon_scene(dialogue_balloon_scene_path, _dialogue_resource, title_to_use, extra_game_states)

	return _dialogue_manager.show_dialogue_balloon(_dialogue_resource, title_to_use, extra_game_states)

#endregion
