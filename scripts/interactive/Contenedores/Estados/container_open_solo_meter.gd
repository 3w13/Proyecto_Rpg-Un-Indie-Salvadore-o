## ContainerOpenSoloMeter
# Estado abierto del cofre con transferencia de SOLO METER.
#
# Lógica 3: el jugador SOLO PUEDE METER objetos en el contenedor.
#   - Al abrir: todos los ítems del jugador pasan al contenedor (Player → Contenedor).
#   - El jugador NO puede sacar objetos del contenedor.
#   - El contenedor permanece abierto aunque tenga objetos; solo cierra si el jugador
#     sale del rango o si no hay nada que depositar.
extends "res://scripts/interactive/Contenedores/state_base.gd"

# Clave de metadata usada para recuperar el jugador que abrió el cofre.
const _INTERACTING_PLAYER_META_KEY: StringName = &"container_interacting_player"

# Ruta al sprite animado del contenedor.
@export var animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")
# Acción de input usada para interactuar con el cofre.
@export var interaction_action: StringName = &"interact"
# Ruta al `Area2D` que detecta al jugador.
@export var interaction_area_path: NodePath = NodePath("Area2D")
# Ruta al nodo de inventario interno del contenedor.
@export var inventory_node_path: NodePath = NodePath("ContainerInventory")
# Estado al que vuelve el contenedor cuando el jugador se aleja o no hay más que depositar.
@export var closed_state_path: NodePath = NodePath("ContainerClosed")
# Ruta al nodo de inventario del jugador dentro de su escena.
@export var player_inventory_path: NodePath = NodePath("PlayerInventory")
# Si está activo, imprime en consola el contenido del contenedor al abrirse.
@export var print_inventory_on_start: bool = true

var _interaction_area: Area2D = null
var _player_in_range: bool = false
var _player_node: Node = null


# Al entrar al estado se abre el cofre y recibe los objetos del jugador.
func start() -> void:
	_play_container_animation(&"Abierto")
	_bind_interaction_area_signals()
	_player_node = _get_interacting_player()
	_player_in_range = _player_node != null
	_set_interacting_player(_player_node)

	if _player_in_range:
		_transfer_player_to_container()
	_close_if_player_gone()
	if print_inventory_on_start and state_machine != null and state_machine.current_state == self:
		print_inventory()


# Al salir del estado limpia referencias y desconecta señales del área.
func end() -> void:
	_set_interacting_player(null)
	_unbind_interaction_area_signals()


# En cada frame cierra si el jugador ya no está en rango.
func on_process(_delta: float) -> void:
	_close_if_player_gone()


# Si el jugador vuelve a presionar interact deposita cualquier objeto que tenga encima.
func on_unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if _player_node == null:
		return

	if event.is_action_pressed(interaction_action):
		_set_interacting_player(_player_node)
		_transfer_player_to_container()
		if print_inventory_on_start:
			print_inventory()


# Imprime el contenido actual del contenedor.
func print_inventory() -> void:
	var inventory := _get_container_inventory()
	if inventory == null:
		return
	inventory.print_inventory()


# Transfiere todos los objetos del jugador al contenedor (Player → Contenedor).
func _transfer_player_to_container() -> void:
	var container_inventory := _get_container_inventory()
	if container_inventory == null:
		return

	var player_inventory := _get_player_inventory()
	if player_inventory == null:
		return

	var player_items: Dictionary = player_inventory.get_all_items()
	if player_items.is_empty():
		print("[SoloMeter] El jugador no tiene objetos para depositar")
		return

	for item_id in player_items.keys():
		var amount := int(player_items[item_id])
		if amount <= 0:
			continue
		container_inventory.receive_item(String(item_id), amount)

	player_inventory.clear_inventory()
	print("[SoloMeter] Objetos del jugador depositados en el contenedor")


# Cierra el cofre si el jugador ya no está en rango de interacción.
func _close_if_player_gone() -> void:
	if _player_in_range:
		return
	if state_machine != null:
		state_machine.change_to(closed_state_path)


# Busca el nodo `ContainerInventory` dentro del contenedor.
func _get_container_inventory() -> Node:
	if controlled_node == null:
		return null
	var inventory := controlled_node.get_node_or_null(inventory_node_path)
	if inventory == null:
		push_warning("ContainerOpenSoloMeter: nodo de inventario no encontrado -> " + str(inventory_node_path))
		return null
	return inventory


# Busca el `PlayerInventory` del jugador que abrió el cofre.
func _get_player_inventory() -> Node:
	var player_node := _player_node
	if player_node == null:
		player_node = _get_interacting_player()
	if player_node == null:
		push_warning("ContainerOpenSoloMeter: jugador interactuando no encontrado")
		return null
	var inventory := player_node.get_node_or_null(player_inventory_path)
	if inventory == null:
		push_warning("ContainerOpenSoloMeter: PlayerInventory no encontrado -> " + str(player_inventory_path))
		return null
	return inventory


# Recupera desde metadata la referencia al jugador interactuante.
func _get_interacting_player() -> Node:
	if controlled_node == null:
		return null
	return controlled_node.get_meta(_INTERACTING_PLAYER_META_KEY, null) as Node


# Guarda o borra la referencia del jugador interactuante en metadata del contenedor.
func _set_interacting_player(player_node: Node) -> void:
	if controlled_node == null:
		return
	if player_node == null:
		if controlled_node.has_meta(_INTERACTING_PLAYER_META_KEY):
			controlled_node.remove_meta(_INTERACTING_PLAYER_META_KEY)
		return
	controlled_node.set_meta(_INTERACTING_PLAYER_META_KEY, player_node)


# Conecta señales del área de interacción.
func _bind_interaction_area_signals() -> void:
	if controlled_node == null:
		return
	_interaction_area = controlled_node.get_node_or_null(interaction_area_path) as Area2D
	if _interaction_area == null:
		push_warning("ContainerOpenSoloMeter: Area2D no encontrado en " + str(interaction_area_path))
		return
	_interaction_area.monitoring = true
	_interaction_area.monitorable = true
	if not _interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		_interaction_area.area_entered.connect(_on_interaction_area_entered)
	if not _interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		_interaction_area.area_exited.connect(_on_interaction_area_exited)


# Desconecta señales del área de interacción.
func _unbind_interaction_area_signals() -> void:
	if _interaction_area == null:
		return
	if _interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		_interaction_area.area_entered.disconnect(_on_interaction_area_entered)
	if _interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		_interaction_area.area_exited.disconnect(_on_interaction_area_exited)


# Marca al jugador como dentro del rango.
func _on_interaction_area_entered(area: Area2D) -> void:
	if _is_player_interaction_area(area):
		_player_in_range = true
		_player_node = _resolve_player_from_area(area)
		_set_interacting_player(_player_node)


# Limpia el estado de rango cuando el jugador sale del área.
func _on_interaction_area_exited(area: Area2D) -> void:
	if _is_player_interaction_area(area):
		_player_in_range = false
		_player_node = null
		_set_interacting_player(null)


# Valida si un Area2D corresponde al player.
func _is_player_interaction_area(area: Area2D) -> bool:
	if area == null:
		return false
	if area.is_in_group("player"):
		return true
	var owner_node := area.owner
	if owner_node != null and owner_node.is_in_group("player"):
		return true
	var parent_node := area.get_parent()
	if parent_node != null and parent_node.is_in_group("player"):
		return true
	if area.name == "InteractArea":
		return true
	return false


# Resuelve el nodo player a partir del owner o parent del área.
func _resolve_player_from_area(area: Area2D) -> Node:
	if area == null:
		return null
	var owner_node := area.owner
	if owner_node != null:
		return owner_node
	return area.get_parent()


# Reproduce la animación correspondiente del cofre.
func _play_container_animation(animation_name: StringName) -> void:
	if controlled_node == null:
		return
	var sprite := controlled_node.get_node_or_null(animated_sprite_path) as AnimatedSprite2D
	if sprite == null:
		return
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation_name):
		return
	sprite.play(animation_name)
