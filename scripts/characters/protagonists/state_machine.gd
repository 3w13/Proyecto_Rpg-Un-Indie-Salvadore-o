# StateMachine: orquestador de la máquina de estados basada en adwnodos.
# Cada estado es un nodo hijo que extiende StateBase.
# Para cambiar de estado se usa change_to() pasando el nombre del nodo destino.
class_name StateMachine extends Node

# Referencia al nodo que esta máquina controla (normalmente CharacterBody2D).
@onready var controlled_node:Node = self.owner

# Estado inicial que se activará al arrancar la escena.
@export var default_state:StateBase

# Estado actualmente activo.
var current_state:StateBase = null

func _ready():
	# Se usa call_deferred para esperar a que todos los nodos estén listos.
	call_deferred("_state_default_start")

func _state_default_start() -> void:
	# Arranca el estado por defecto definido en el inspector.
	current_state = default_state
	_state_start()

func _state_start() -> void:
	# Inicializa el estado actual: le pasa el nodo controlado, la referencia
	# a esta máquina, y llama a su método start().
	print("StateMachine ", controlled_node.name, " start state: ", current_state.name)

	current_state.controlled_node = controlled_node
	current_state.state_machine = self
	current_state.start()

func change_to(new_state:String) -> void:
	# Finaliza el estado actual (si tiene método end) y activa el nuevo.
	# new_state debe coincidir exactamente con el nombre del nodo hijo.
	if current_state and current_state.has_method("end"):
		current_state.end()
	var next := get_node_or_null(new_state) as StateBase
	if next == null:
		push_warning("StateMachine: estado no encontrado -> " + new_state)
		return
	print("StateMachine ", controlled_node.name, " cambio de estado: ", current_state.name, " -> ", next.name)
	current_state = next
	_state_start()


#region Delegación de callbacks de Godot al estado activo
# Cada método revisa si el estado implementa el callback antes de llamarlo,
# así los estados solo definen los métodos que realmente necesitan.

func _process(_delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(_delta)

func _physics_process(_delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(_delta)

func _input(_event:InputEvent) -> void:
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(_event)

func _unhandled_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(_event)

func _unhandled_key_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(_event)


#endregion
