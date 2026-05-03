## PlayerStateEnterInventory
# Estado temporal de entrada al inventario del jugador.
#
# Por ahora solo inmoviliza al player y muestra en consola el contenido
# del nodo `PlayerInventory`. Más adelante servirá como base para la
# navegación dentro de la UI del inventario.
extends StateBase

# Si está activo, al entrar al estado se imprime el inventario en consola.
@export var print_on_start: bool = true
# Ruta al nodo `PlayerInventory` dentro del player.
@export var inventory_node_path: NodePath = "PlayerInventory"


# Al entrar al estado se muestra el contenido actual del inventario.
func start() -> void:
	if print_on_start:
		print_inventory()


# Mientras el inventario está abierto, el jugador queda inmóvil.
func on_physics_process(_delta: float) -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return

	player.velocity = Vector2.ZERO
	player.move_and_slide()


# Reenvía la recepción de objetos al nodo `PlayerInventory`.
func receive_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_player_inventory()
	if inventory == null:
		return false
	return inventory.receive_item(item_id, amount)


# Reenvía la entrega de objetos al nodo `PlayerInventory`.
func send_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_player_inventory()
	if inventory == null:
		return false
	return inventory.send_item(item_id, amount)


# Reenvía la suma de objetos al inventario real del jugador.
func add_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_player_inventory()
	if inventory == null:
		return false
	return inventory.add_item(item_id, amount)


# Reenvía la eliminación de objetos al inventario real del jugador.
func remove_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_player_inventory()
	if inventory == null:
		return false
	return inventory.remove_item(item_id, amount)


# Verifica si el inventario del jugador tiene un objeto.
func has_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_player_inventory()
	if inventory == null:
		return false
	return inventory.has_item(item_id, amount)


# Consulta la cantidad de un objeto en el inventario del jugador.
func get_item_count(item_id: String) -> int:
	var inventory := _get_player_inventory()
	if inventory == null:
		return 0
	return inventory.get_item_count(item_id)


# Devuelve una copia del contenido total del inventario del jugador.
func get_all_items() -> Dictionary:
	var inventory := _get_player_inventory()
	if inventory == null:
		return {}
	return inventory.get_all_items()


# Vacía el inventario del jugador usando su propio nodo.
func clear_inventory() -> void:
	var inventory := _get_player_inventory()
	if inventory == null:
		return
	inventory.clear_inventory()


# Imprime en consola el inventario del jugador.
func print_inventory() -> void:
	var inventory := _get_player_inventory()
	if inventory == null:
		return
	inventory.print_inventory()


# Busca y devuelve el nodo `PlayerInventory` del jugador controlado.
func _get_player_inventory() -> Node:
	if controlled_node == null:
		return null

	var inventory := controlled_node.get_node_or_null(inventory_node_path)
	if inventory == null:
		push_warning("PlayerStateEnterInventory: nodo de inventario no encontrado -> " + str(inventory_node_path))
		return null

	return inventory
