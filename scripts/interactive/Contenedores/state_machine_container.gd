## ContainerStateMachine
# Máquina de estados simple para objetos interactivos tipo contenedor.
#
# Controla un nodo propietario, activa un estado por defecto y delega los
# callbacks de Godot al estado actualmente activo.
class_name ContainerStateMachine extends Node

# Ruta al estado inicial de la máquina.
@export var default_state: NodePath
# Ruta opcional al nodo controlado. Si está vacía, usa el `owner`.
@export var controlled_node_path: NodePath

# Nodo del contenedor que esta máquina controla.
var controlled_node: Node = null
# Estado activo actual.
var current_state: Node = null


# Resuelve el nodo controlado y arranca el estado por defecto.
func _ready() -> void:
	if controlled_node_path != NodePath(""):
		controlled_node = get_node_or_null(controlled_node_path)
	else:
		controlled_node = owner
	
	call_deferred("_start_default_state")


# Activa el estado configurado como predeterminado.
func _start_default_state() -> void:
	if default_state == NodePath(""):
		push_warning("ContainerStateMachine: default_state no configurado")
		return
	
	var state := get_node_or_null(default_state)
	if state == null:
		push_warning("ContainerStateMachine: default_state inválido -> " + str(default_state))
		return
	
	_set_state(state)


# Solicita un cambio de estado usando una ruta relativa a la máquina.
func change_to(state_path: NodePath) -> void:
	var next_state := get_node_or_null(state_path)
	if next_state == null:
		push_warning("ContainerStateMachine: estado no encontrado -> " + str(state_path))
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
	
	print("ContainerStateMachine:", name, " -> ", current_state.name)


# Delegación del callback `_process` al estado activo.
func _process(delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(delta)


# Delegación del callback `_physics_process` al estado activo.
func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(delta)


# Delegación del callback `_input` al estado activo.
func _input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(event)


# Delegación del callback `_unhandled_input` al estado activo.
func _unhandled_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(event)


# Delegación del callback `_unhandled_key_input` al estado activo.
func _unhandled_key_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(event)
