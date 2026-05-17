## CofreOpen
# Estado abierto del cofre.
#
# Reproduce la animación de apertura y aplica la transferencia bidireccional:
#   - Player con items + Contenedor vacío  → items pasan de Player a Contenedor.
#   - Player vacío   + Contenedor con items → items pasan de Contenedor a Player.
#   - Cualquier otro caso (ambos llenos o ambos vacíos) → no se transfiere nada.
extends "res://scripts/interactive/Contenedores/cofre_state_base.gd"

# Clave de metadata usada para recuperar el jugador que abrió el cofre.
const _INTERACTING_PLAYER_META_KEY: StringName = &"cofre_interacting_player"

const _TRANSFER_NONE: int = 0
const _TRANSFER_PLAYER_TO_CONTAINER: int = 1
const _TRANSFER_CONTAINER_TO_PLAYER: int = 2

# Ruta al sprite animado del contenedor.
@export var animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")
# Acción de input usada para interactuar con el cofre.
@export var interaction_action: StringName = &"interact"
# Ruta al `Area2D` que detecta al jugador.
@export var interaction_area_path: NodePath = GameConstants.node_container_interaction_area()
# Ruta al nodo de inventario interno del contenedor.
@export var inventory_node_path: NodePath = NodePath("CofreInventory")
# Estado al que vuelve el contenedor cuando está vacío.
@export var closed_state_path: NodePath = NodePath("CofreClosed")
# Ruta al nodo de inventario del jugador dentro de su escena.
@export var player_inventory_path: NodePath = NodePath("PlayerInventory")
# Si está activo, imprime en consola el contenido del contenedor al abrirse.
@export var print_inventory_on_start: bool = true

# Grupo y nombre de área usados para reconocer al player.
@export var player_group: StringName = GameConstants.group_player()
@export var player_interact_area_name: StringName = GameConstants.node_player_interact_area_name()

var _interaction_area: Area2D = null
var _player_in_range: bool = false
var _player_node: Node = null


# Al entrar al estado se abre el cofre y se intenta transferir su contenido.
func start() -> void:
	_play_container_animation(&"Abierto")
	_bind_interaction_area_signals()
	_player_node = _get_interacting_player()
	_player_in_range = _player_node != null
	_set_interacting_player(_player_node)

	if _player_in_range:
		var transfer_result := _transfer_items_from_player()
		_close_after_transfer(transfer_result)
		# Si se transfirió del jugador al contenedor, el cofre ya cambió a CLOSED:
		# no continuar ejecutando lógica del estado OPEN.
		if transfer_result == _TRANSFER_PLAYER_TO_CONTAINER:
			return
	_close_if_empty()
	# Solo imprimir el inventario si el estado sigue activo (no transicionó a CLOSED).
	if print_inventory_on_start and state_machine != null and state_machine.current_state == self:
		print_inventory()


# Al salir del estado limpia referencias y desconecta señales del área.
func end() -> void:
	_set_interacting_player(null)
	_unbind_interaction_area_signals()


# En cada frame, si el contenedor queda vacío, regresa a CLOSED.
func on_process(_delta: float) -> void:
	_close_if_empty()


# Si el jugador vuelve a presionar interact estando el cofre abierto,
# se ejecuta otra transferencia (permite recoger lo que acaba de depositar).
func on_unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if _player_node == null:
		return

	if event.is_action_pressed(interaction_action):
		_set_interacting_player(_player_node)
		var transfer_result := _transfer_items_from_player()
		_close_after_transfer(transfer_result)
		_close_if_empty()
		if print_inventory_on_start:
			print_inventory()


# Imprime el contenido actual del contenedor.
func print_inventory() -> void:
	var inventory := _get_container_inventory()
	if inventory == null:
		return

	inventory.print_inventory()


# Reenvía la recepción de objetos al inventario interno del contenedor.
func receive_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_container_inventory()
	if inventory == null:
		return false
	return inventory.receive_item(item_id, amount)


# Reenvía la entrega de objetos al inventario interno del contenedor.
func send_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_container_inventory()
	if inventory == null:
		return false
	return inventory.send_item(item_id, amount)


# Agrega objetos al inventario del contenedor.
func add_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_container_inventory()
	if inventory == null:
		return false
	return inventory.add_item(item_id, amount)


# Quita objetos del inventario del contenedor.
func remove_item(item_id: String, amount: int = 1) -> bool:
	var inventory := _get_container_inventory()
	if inventory == null:
		return false
	return inventory.remove_item(item_id, amount)


# Devuelve una copia del contenido actual del contenedor.
func get_all_items() -> Dictionary:
	var inventory := _get_container_inventory()
	if inventory == null:
		return {}
	return inventory.get_all_items()


# Busca el nodo `CofreInventory` dentro del contenedor.
func _get_container_inventory() -> Node:
	if controlled_node == null:
		return null

	var inventory := controlled_node.get_node_or_null(inventory_node_path)
	if inventory == null:
		push_warning("CofreOpen: nodo de inventario no encontrado -> " + str(inventory_node_path))
		return null

	return inventory



# Transferencia bidireccional según el estado de cada inventario al abrir el cofre.
# Player lleno  + Contenedor vacío  → Player → Contenedor.
# Player vacío  + Contenedor lleno  → Contenedor → Player.
# Cualquier otro caso → sin transferencia.
func _transfer_items_from_player() -> int:
	var container_inventory := _get_container_inventory()
	if container_inventory == null:
		return _TRANSFER_NONE

	var player_inventory := _get_player_inventory()
	if player_inventory == null:
		return _TRANSFER_NONE

	var player_items: Dictionary = player_inventory.get_all_items()
	var container_items: Dictionary = container_inventory.get_all_items()

	var player_has_items: bool = not player_items.is_empty()
	var container_has_items: bool = not container_items.is_empty()

	if player_has_items and not container_has_items:
		# Player → Contenedor
		for item_id in player_items.keys():
			var amount := int(player_items[item_id])
			if amount <= 0:
				continue
			container_inventory.receive_item(String(item_id), amount)
		player_inventory.clear_inventory()
		print("[Contenedor] Objetos del jugador transferidos al contenedor")
		return _TRANSFER_PLAYER_TO_CONTAINER

	elif not player_has_items and container_has_items:
		# Contenedor → Player
		var transfer_done: bool = false
		if player_inventory.has_method("receive_items"):
			transfer_done = player_inventory.receive_items(container_items)
		else:
			for item_id in container_items.keys():
				var amount := int(container_items[item_id])
				if amount <= 0:
					continue
				if player_inventory.receive_item(String(item_id), amount):
					transfer_done = true

		if transfer_done:
			container_inventory.clear_inventory()
			print("[Contenedor] Objetos del contenedor transferidos al jugador")
			return _TRANSFER_CONTAINER_TO_PLAYER

		return _TRANSFER_NONE

	else:
		print("[Contenedor] Sin transferencia: ambos inventarios en el mismo estado")
		return _TRANSFER_NONE


# Tras transferir del player al contenedor, vuelve al estado cerrado.
func _close_after_transfer(transfer_result: int) -> void:
	if transfer_result != _TRANSFER_PLAYER_TO_CONTAINER:
		return

	if state_machine != null:
		state_machine.change_to(closed_state_path)


# Si el contenedor NO tiene objetos, vuelve a CLOSED. Si tiene objetos, se mantiene OPEN.
func _close_if_empty() -> void:
	var container_inventory := _get_container_inventory()
	if container_inventory == null:
		return

	var container_items: Dictionary = container_inventory.get_all_items()
	if not container_items.is_empty():
		return

	if state_machine != null:
		state_machine.change_to(closed_state_path)


# Busca el `PlayerInventory` del jugador que abrió el cofre.
func _get_player_inventory() -> Node:
	var player_node := _player_node
	if player_node == null:
		player_node = _get_interacting_player()
	if player_node == null:
		push_warning("CofreOpen: jugador interactuando no encontrado")
		return null

	var inventory := player_node.get_node_or_null(player_inventory_path)
	if inventory == null:
		push_warning("CofreOpen: PlayerInventory no encontrado -> " + str(player_inventory_path))
		return null

	return inventory


# Recupera desde metadata la referencia al jugador interactuante.
func _get_interacting_player() -> Node:
	if controlled_node == null:
		return null

	return controlled_node.get_meta(_INTERACTING_PLAYER_META_KEY, null) as Node


# Conecta señales del área de interacción para detectar entrada/salida del jugador.
func _bind_interaction_area_signals() -> void:
	if controlled_node == null:
		return

	_interaction_area = controlled_node.get_node_or_null(interaction_area_path) as Area2D
	if _interaction_area == null:
		push_warning("CofreOpen: Area2D no encontrado en " + str(interaction_area_path))
		return

	_interaction_area.monitoring = true
	_interaction_area.monitorable = true

	if not _interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		_interaction_area.area_entered.connect(_on_interaction_area_entered)

	if not _interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		_interaction_area.area_exited.connect(_on_interaction_area_exited)


# Desconecta señales del área de interacción al finalizar el estado.
func _unbind_interaction_area_signals() -> void:
	if _interaction_area == null:
		return

	if _interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		_interaction_area.area_entered.disconnect(_on_interaction_area_entered)

	if _interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		_interaction_area.area_exited.disconnect(_on_interaction_area_exited)


# Marca al jugador como dentro del rango e inicializa su referencia.
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


# Guarda o borra la referencia del jugador interactuante en metadata del contenedor.
func _set_interacting_player(player_node: Node) -> void:
	if controlled_node == null:
		return

	if player_node == null:
		if controlled_node.has_meta(_INTERACTING_PLAYER_META_KEY):
			controlled_node.remove_meta(_INTERACTING_PLAYER_META_KEY)
		return

	controlled_node.set_meta(_INTERACTING_PLAYER_META_KEY, player_node)


# Valida si un Area2D corresponde al player usando grupo, owner, parent o nombre.
func _is_player_interaction_area(area: Area2D) -> bool:
	if area == null:
		return false

	if area.is_in_group(player_group):
		return true

	var owner_node := area.owner
	if owner_node != null and owner_node.is_in_group(player_group):
		return true

	var parent_node := area.get_parent()
	if parent_node != null and parent_node.is_in_group(player_group):
		return true

	if player_interact_area_name != &"" and area.name == String(player_interact_area_name):
		return true

	return false


# Resuelve el nodo player a partir del owner o parent del área detectada.
func _resolve_player_from_area(area: Area2D) -> Node:
	if area == null:
		return null

	var owner_node := area.owner
	if owner_node != null:
		return owner_node

	var parent_node := area.get_parent()
	if parent_node != null:
		return parent_node

	return null


# Reproduce la animación correspondiente del cofre abierto.
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
