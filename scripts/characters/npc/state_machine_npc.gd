# NPCStateMachine: orquestador de la máquina de estados para NPC.
# Cada estado debe ser un nodo hijo que extienda NPCStateBase.
class_name NPCStateMachine extends Node

# Nodo que esta máquina controla (normalmente CharacterBody2D del NPC).
@onready var controlled_node: Node = self.owner

# Estado inicial configurado desde el inspector.
@export var default_state: NPCStateBase

# Estado activo actual.
var current_state: NPCStateBase = null

# Estados que solo pueden activarse por interacción explícita (ej. tecla E en área de interacción).
@export var interaction_only_states: PackedStringArray = ["NpcStateDialogue"]

# Solicitud temporal de transición por interacción.
var _pending_interaction_state: String = ""

# Arranca la máquina diferida para asegurar nodos listos.
func _ready() -> void:
	# Espera a que todos los nodos estén listos antes de iniciar.
	call_deferred("_state_default_start")

# Activa el estado por defecto configurado.
func _state_default_start() -> void:
	current_state = default_state
	_state_start()

# Inicializa y ejecuta la entrada del estado activo.
func _state_start() -> void:
	if current_state == null:
		push_warning("NPCStateMachine: default_state no asignado en " + name)
		return

	print("NPCStateMachine ", controlled_node.name, " start state: ", current_state.name)
	current_state.controlled_node = controlled_node
	current_state.state_machine = self
	current_state.start()

# Solicita transición a un estado por nombre.
func change_to(new_state: String) -> void:
	var next := get_node_or_null(new_state) as NPCStateBase
	if next == null:
		push_warning("NPCStateMachine: estado no encontrado -> " + new_state)
		return

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


# Habilita de forma temporal una transición explícita por interacción.
func request_interaction_transition(new_state: String) -> void:
	_pending_interaction_state = new_state
	change_to(new_state)
	_pending_interaction_state = ""


# Determina si un estado es exclusivo de interacción manual.
func _is_interaction_only_state(state_name: String, state_node: NPCStateBase = null) -> bool:
	if interaction_only_states.has(state_name):
		return true

	if state_node != null and state_node.manual_trigger_only:
		return true

	return false

#region Delegación de callbacks al estado activo

func _process(_delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(_delta)

# Reenvía `_physics_process` al estado activo cuando existe.
func _physics_process(_delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(_delta)

# Reenvía `_input` al estado activo cuando existe.
func _input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(_event)

# Reenvía `_unhandled_input` al estado activo cuando existe.
func _unhandled_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(_event)

# Reenvía `_unhandled_key_input` al estado activo cuando existe.
func _unhandled_key_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(_event)

#endregion
