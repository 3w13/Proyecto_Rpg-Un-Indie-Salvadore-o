# NPCStateMachine: orquestador de la máquina de estados para NPC.
# Cada estado debe ser un nodo hijo que extienda NPCStateBase.
class_name NPCStateMachine extends Node

# Nodo que esta máquina controla (normalmente CharacterBody2D del NPC).
@onready var controlled_node: Node = self.owner

# Estado inicial configurado desde el inspector.
@export var default_state: NPCStateBase

# Estado activo actual.
var current_state: NPCStateBase = null

func _ready() -> void:
	# Espera a que todos los nodos estén listos antes de iniciar.
	call_deferred("_state_default_start")

func _state_default_start() -> void:
	current_state = default_state
	_state_start()

func _state_start() -> void:
	if current_state == null:
		push_warning("NPCStateMachine: default_state no asignado en " + name)
		return

	print("NPCStateMachine ", controlled_node.name, " start state: ", current_state.name)
	current_state.controlled_node = controlled_node
	current_state.state_machine = self
	current_state.start()

func change_to(new_state: String) -> void:
	if current_state and current_state.has_method("end"):
		current_state.end()

	var next := get_node_or_null(new_state) as NPCStateBase
	if next == null:
		push_warning("NPCStateMachine: estado no encontrado -> " + new_state)
		return

	var previous_name := "<none>"
	if current_state:
		previous_name = current_state.name

	print("NPCStateMachine ", controlled_node.name, " cambio de estado: ", previous_name, " -> ", next.name)
	current_state = next
	_state_start()

#region Delegación de callbacks al estado activo

func _process(_delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(_delta)

func _physics_process(_delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(_delta)

func _input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(_event)

func _unhandled_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(_event)

func _unhandled_key_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(_event)

#endregion
