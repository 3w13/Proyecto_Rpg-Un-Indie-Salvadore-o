# PlayerStateMachine: orquestador de la máquina de estados del jugador.
# Cada estado es un nodo hijo que extiende StateBase.
# Para cambiar de estado se usa change_to() pasando el nombre del nodo destino.
class_name PlayerStateMachine extends Node

# Referencia al nodo que esta máquina controla (normalmente CharacterBody2D).
@onready var controlled_node:Node = self.owner

# Estado inicial que se activará al arrancar la escena.
@export var default_state:StateBase

# Estado usado para bloquear movimiento mientras hay diálogo activo.
@export var dialogue_state_name: String = "PlayerStateDialogue"

# Estado al que vuelve el jugador cuando termina el diálogo.
@export var post_dialogue_state_name: String = "PlayerStateIdle"

# Estado de inventario y tecla temporal para abrir/cerrar.
@export var inventory_state_name: String = "PlayerStateEnterInventory"
@export var inventory_toggle_key: Key = KEY_I

# Estado actualmente activo.
var current_state:StateBase = null
var _previous_state_before_inventory: String = ""

# Referencia al singleton de Dialogue Manager.
var _dialogue_manager: Node = null

# Inicializa señales y arranca el estado por defecto al final del frame.
func _ready():
	_configure_character_body_physics()
	# Vincula señales globales y arranca el estado inicial al final del frame.
	_bind_dialogue_signals()
	# Se usa call_deferred para esperar a que todos los nodos estén listos.
	call_deferred("_state_default_start")


# Desconecta señales al salir del árbol para evitar referencias colgantes.
func _exit_tree() -> void:
	# Limpia las conexiones al salir del árbol para evitar referencias colgantes.
	_unbind_dialogue_signals()

# Asigna y arranca el estado inicial configurado en inspector.
func _state_default_start() -> void:
	# Arranca el estado por defecto definido en el inspector.
	current_state = default_state
	_state_start()

# Inyecta dependencias del estado actual y ejecuta su entrada.
func _state_start() -> void:
	# Inicializa el estado actual: le pasa el nodo controlado, la referencia
	# a esta máquina, y llama a su método start().
	if current_state == null:
		push_warning("PlayerStateMachine: current_state es null en " + name)
		return

	#print("PlayerStateMachine ", controlled_node.name, " start state: ", current_state.name)

	current_state.controlled_node = controlled_node
	current_state.state_machine = self as Node
	current_state.start()

# Cambia al estado solicitado por nombre de nodo hijo.
func change_to(new_state:String) -> void:
	# Finaliza el estado actual (si tiene método end) y activa el nuevo.
	# new_state debe coincidir exactamente con el nombre del nodo hijo.
	var next := get_node_or_null(new_state) as StateBase
	if next == null:
		push_warning("PlayerStateMachine: estado no encontrado -> " + new_state)
		return
	if current_state and current_state.has_method("end"):
		current_state.end()
	#print("PlayerStateMachine ", controlled_node.name, " cambio de estado: ", current_state.name, " -> ", next.name)
	current_state = next
	_state_start()


# Conecta eventos globales de inicio/fin de diálogo.
func _bind_dialogue_signals() -> void:
	# Conecta la máquina a los eventos globales del sistema de diálogo.
	if _dialogue_manager == null:
		_dialogue_manager = Engine.get_singleton("DialogueManager")
	if _dialogue_manager == null:
		return

	if not _dialogue_manager.dialogue_started.is_connected(_on_dialogue_started):
		_dialogue_manager.dialogue_started.connect(_on_dialogue_started)

	if not _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)


# Desconecta eventos globales de diálogo previamente enlazados.
func _unbind_dialogue_signals() -> void:
	# Desconecta las señales previamente conectadas al gestor de diálogo.
	if _dialogue_manager == null:
		return

	if _dialogue_manager.dialogue_started.is_connected(_on_dialogue_started):
		_dialogue_manager.dialogue_started.disconnect(_on_dialogue_started)

	if _dialogue_manager.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue_manager.dialogue_ended.disconnect(_on_dialogue_ended)


# Fuerza transición al estado de diálogo cuando una conversación comienza.
func _on_dialogue_started(_resource) -> void:
	# Cambia al estado de diálogo cuando se inicia una conversación.
	if dialogue_state_name == "":
		return
	if current_state == null:
		return
	if current_state.name == dialogue_state_name:
		return
	if get_node_or_null(dialogue_state_name) == null:
		return

	change_to(dialogue_state_name)


# Devuelve al estado configurado al terminar una conversación.
func _on_dialogue_ended(_resource) -> void:
	# Al terminar el diálogo, vuelve al estado configurado de salida.
	if current_state == null:
		return
	if current_state.name != dialogue_state_name:
		return

	if post_dialogue_state_name != "" and get_node_or_null(post_dialogue_state_name) != null:
		change_to(post_dialogue_state_name)
		return

	if default_state != null:
		var default_state_name := String(default_state.name)
		if get_node_or_null(NodePath(default_state_name)) != null:
			change_to(default_state_name)


# Hook temporal para transición a batalla cuando un enemy alcanza al player.
func notify_enemy_encounter() -> void:
	print("Cambio a esena de batalla")


func _configure_character_body_physics() -> void:
	var body := controlled_node as CharacterBody2D
	if body == null:
		return

	body.collision_layer = GameConstants.physics_layer_character_body()
	body.collision_layer = GameConstants.PHYSICS_LAYER_CHARACTER_BODY
	body.collision_mask = GameConstants.PHYSICS_MASK_WORLD_ONLY


#region Delegación de callbacks de Godot al estado activo
# Cada método revisa si el estado implementa el callback antes de llamarlo,
# así los estados solo definen los métodos que realmente necesitan.

func _process(_delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(_delta)

# Reenvía `_physics_process` al estado activo cuando existe.
func _physics_process(_delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(_delta)

# Reenvía `_input` al estado activo cuando existe.
func _input(_event:InputEvent) -> void:
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(_event)

# Reenvía `_unhandled_input` al estado activo cuando existe.
func _unhandled_input(_event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(_event)

# Gestiona hotkey de inventario y, si no aplica, reenvía al estado activo.
func _unhandled_key_input(_event: InputEvent) -> void:
	# La tecla I tiene prioridad para abrir/cerrar el estado de inventario.
	if _is_inventory_toggle_event(_event):
		_toggle_inventory_state()
		return

	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(_event)


# Detecta si el evento corresponde a la tecla configurada para inventario.
func _is_inventory_toggle_event(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	if key_event == null:
		return false

	if not key_event.pressed or key_event.echo:
		return false

	return key_event.keycode == inventory_toggle_key


# Alterna entre el estado actual y el estado de inventario.
# Guarda el estado previo para poder volver correctamente al salir.
func _toggle_inventory_state() -> void:
	if inventory_state_name == "":
		return

	var inventory_state := get_node_or_null(inventory_state_name) as StateBase
	if inventory_state == null:
		return

	if current_state == null:
		change_to(inventory_state_name)
		print("[SPRITE] Entrada inventario")
		return

	if String(current_state.name) != inventory_state_name:
		_previous_state_before_inventory = String(current_state.name)
		change_to(inventory_state_name)
		print("[SPRITE] Entrada inventario")
		return

	var return_state_name := _previous_state_before_inventory
	if return_state_name == "" or return_state_name == inventory_state_name or get_node_or_null(return_state_name) == null:
		if default_state != null:
			return_state_name = String(default_state.name)

	if return_state_name != "" and get_node_or_null(return_state_name) != null:
		change_to(return_state_name)
		print("[SPRITE] Salida inventario")


#endregion
