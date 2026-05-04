extends Node

@export var default_state: NodePath
@export var controlled_node_path: NodePath

var controlled_node: Node = null
var current_state: Node = null


# Resuelve nodo controlado y arranca estado por defecto al final del frame.
func _ready() -> void:
	if controlled_node_path != NodePath(""):
		controlled_node = get_node_or_null(controlled_node_path)
	else:
		controlled_node = owner
	
	call_deferred("_start_default_state")


# Activa el estado configurado como predeterminado.
func _start_default_state() -> void:
	if default_state == NodePath(""):
		push_warning("StateMachine: default_state no configurado")
		return
	
	var state := get_node_or_null(default_state)
	if state == null:
		push_warning("StateMachine: default_state inválido -> " + str(default_state))
		return
	
	_set_state(state)


# Solicita cambio de estado usando una ruta relativa a la máquina.
func change_to(state_path: NodePath) -> void:
	var next_state := get_node_or_null(state_path)
	if next_state == null:
		push_warning("StateMachine: estado no encontrado -> " + str(state_path))
		return
	
	_set_state(next_state)


# Finaliza el estado actual e inicializa el siguiente.
func _set_state(next_state: Node) -> void:
	if current_state == next_state:
		return
	
	if current_state and current_state.has_method("end"):
		current_state.end()
	
	current_state = next_state
	
	if "controlled_node" in current_state:
		current_state.set("controlled_node", controlled_node)
	if "state_machine" in current_state:
		current_state.set("state_machine", self)
	
	if current_state.has_method("start"):
		current_state.start()
	
	print("StateMachine:", name, " -> ", current_state.name)


# Reenvía `_process` al estado activo cuando existe.
func _process(delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(delta)


# Reenvía `_physics_process` al estado activo cuando existe.
func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(delta)


# Reenvía `_input` al estado activo cuando existe.
func _input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(event)


# Reenvía `_unhandled_input` al estado activo cuando existe.
func _unhandled_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(event)


# Reenvía `_unhandled_key_input` al estado activo cuando existe.
func _unhandled_key_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(event)
