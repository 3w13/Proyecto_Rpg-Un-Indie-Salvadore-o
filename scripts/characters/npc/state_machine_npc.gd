# NPCStateMachine: orquestador de la máquina de estados para NPC.
# Cada estado debe ser un nodo hijo que extienda NPCStateBase.
class_name NPCStateMachine extends Node


#region Exportaciones

# Nodo que esta máquina controla (normalmente CharacterBody2D del NPC).
@onready var controlled_node: Node = self.owner

# Estado inicial configurado desde el inspector.
@export var default_state: NPCStateBase

# Estados que solo pueden activarse por interacción explícita (ej. tecla E en área de interacción).
@export var interaction_only_states: PackedStringArray = ["NpcStateDialogue"]

#endregion


#region Variables

# Estado activo actual.
var current_state: NPCStateBase = null

# Estado de interacción pendiente de activar.
# Se usa para permitir temporalmente una transición a un estado de interacción exclusiva.
var _pending_interaction_state: String = ""

#endregion


#region Ciclo de vida del nodo

# Configura física y arranca el estado por defecto al final del frame.
func _ready() -> void:
	_configure_character_body_physics()
	# call_deferred garantiza que todos los nodos hijos estén listos antes de arrancar.
	call_deferred("_state_default_start")

#endregion


#region Gestión de estados

# Activa el estado por defecto configurado en el inspector.
func _state_default_start() -> void:
	current_state = default_state
	_state_start()


# Inyecta dependencias en el estado activo y ejecuta su entrada.
func _state_start() -> void:
	if current_state == null:
		push_warning("NPCStateMachine: default_state no asignado en " + name)
		return

	print("NPCStateMachine ", controlled_node.name, " start state: ", current_state.name)
	current_state.controlled_node = controlled_node
	current_state.state_machine = self
	current_state.start()


# Solicita transición a un estado por nombre de nodo hijo.
# Bloquea la transición si el estado destino es de interacción exclusiva
# y no fue solicitado explícitamente mediante request_interaction_transition.
func change_to(new_state: String) -> void:
	var next := get_node_or_null(new_state) as NPCStateBase
	if next == null:
		push_warning("NPCStateMachine: estado no encontrado -> " + new_state)
		return

	# Bloquear transición automática a estados de interacción exclusiva.
	if _is_interaction_only_state(new_state, next) and _pending_interaction_state != new_state:
		print("NPCStateMachine ", controlled_node.name, " transición bloqueada a estado de interacción: ", new_state)
		return

	if current_state and current_state.has_method("end"):
		current_state.end()

	var previous_name := "<none>"
	if current_state:
		previous_name = current_state.name

	print("NPCStateMachine ", controlled_node.name, " cambio de estado: ", previous_name, " -> ", next.name)
	current_state = next
	_state_start()


# Habilita temporalmente una transición a un estado de interacción exclusiva.
# Establece el estado pendiente, ejecuta el cambio y limpia la autorización.
func request_interaction_transition(new_state: String) -> void:
	_pending_interaction_state = new_state
	change_to(new_state)
	_pending_interaction_state = ""


# Devuelve true si el estado indicado es de interacción exclusiva.
# Comprueba tanto la lista interaction_only_states como el flag manual_trigger_only del nodo.
func _is_interaction_only_state(state_name: String, state_node: NPCStateBase = null) -> bool:
	if interaction_only_states.has(state_name):
		return true

	if state_node != null and state_node.manual_trigger_only:
		return true

	return false

#endregion


#region Física y utilidades

# Configura las capas de colisión del CharacterBody2D según las constantes del juego.
func _configure_character_body_physics() -> void:
	var body := controlled_node as CharacterBody2D
	if body == null:
		return
	body.collision_layer = GameConstants.PHYSICS_LAYER_CHARACTER_BODY
	body.collision_mask = GameConstants.PHYSICS_MASK_WORLD_ONLY

#endregion


#region Delegación de callbacks al estado activo
# Cada método comprueba si el estado activo implementa el callback antes de llamarlo,
# de modo que los estados solo definen los métodos que realmente necesitan.

func _process(_delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(_delta)

# Reenvía _physics_process al estado activo cuando existe.
func _physics_process(_delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(_delta)

# Reenvía _input al estado activo cuando existe.
func _input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(_event)

# Reenvía _unhandled_input al estado activo cuando existe.
func _unhandled_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(_event)

# Reenvía _unhandled_key_input al estado activo cuando existe.
func _unhandled_key_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(_event)

#endregion
