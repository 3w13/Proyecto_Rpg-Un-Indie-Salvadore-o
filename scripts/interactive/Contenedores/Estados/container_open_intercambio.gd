## ContainerOpenIntercambio
# Estado abierto del cofre con lógica de INTERCAMBIO.
#
# Lógica 4: el jugador ENTREGA un objeto específico y RECIBE otro a cambio.
#   - Al interactuar: si el jugador tiene `required_item_id` en su inventario,
#     se le quita esa cantidad y se le entrega `reward_item_id`.
#   - Si el jugador no tiene el objeto requerido, el intercambio no ocurre y se
#     notifica por consola.
#   - El cofre puede configurarse para ser de un solo uso (cierra tras el primer
#     intercambio exitoso) o reutilizable.
#   - Si `reward_item_id` está vacío, el contenedor simplemente acepta el objeto
#     sin dar nada a cambio (donación/ofrenda).
extends "res://scripts/interactive/Contenedores/state_base.gd"

# Clave de metadata usada para recuperar el jugador que abrió el cofre.
const _INTERACTING_PLAYER_META_KEY: StringName = &"container_interacting_player"

# Ruta al sprite animado del contenedor.
@export var animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")
# Acción de input usada para interactuar con el cofre.
@export var interaction_action: StringName = &"interact"
# Ruta al `Area2D` que detecta al jugador.
@export var interaction_area_path: NodePath = NodePath("Area2D")
# Estado al que vuelve el contenedor tras un intercambio o cuando no hay jugador.
@export var closed_state_path: NodePath = NodePath("ContainerClosed")
# Ruta al nodo de inventario del jugador dentro de su escena.
@export var player_inventory_path: NodePath = NodePath("PlayerInventory")

# ID del objeto que el jugador debe ENTREGAR al contenedor.
@export var required_item_id: String = ""
# Cantidad del objeto requerido.
@export var required_amount: int = 1
# ID del objeto que el jugador RECIBIRÁ a cambio.
# Si se deja vacío, el contenedor acepta el objeto sin dar nada (modo ofrenda).
@export var reward_item_id: String = ""
# Cantidad del objeto de recompensa.
@export var reward_amount: int = 1
# Si es `true`, el cofre cierra automáticamente tras el primer intercambio exitoso.
@export var single_use: bool = true

var _interaction_area: Area2D = null
var _player_in_range: bool = false
var _player_node: Node = null
# Rastrea si ya se realizó el intercambio (para modo single_use).
var _exchange_done: bool = false


# Al entrar al estado se abre el cofre e intenta el intercambio de inmediato.
func start() -> void:
	_exchange_done = false
	_play_container_animation(&"Abierto")
	_bind_interaction_area_signals()
	_player_node = _get_interacting_player()
	_player_in_range = _player_node != null
	_set_interacting_player(_player_node)

	if _player_in_range:
		_try_exchange()


# Al salir del estado limpia referencias y desconecta señales del área.
func end() -> void:
	_set_interacting_player(null)
	_unbind_interaction_area_signals()


# Si el jugador vuelve a presionar interact y no es single_use, intenta otro intercambio.
func on_unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if _player_node == null:
		return
	if single_use and _exchange_done:
		return

	if event.is_action_pressed(interaction_action):
		_set_interacting_player(_player_node)
		_try_exchange()


# Intenta realizar el intercambio entre el jugador y el contenedor.
func _try_exchange() -> void:
	if required_item_id.strip_edges() == "":
		push_warning("ContainerOpenIntercambio: required_item_id no configurado")
		return

	var player_inventory := _get_player_inventory()
	if player_inventory == null:
		return

	# Verificar si el jugador tiene el objeto requerido.
	if not player_inventory.has_method("has_item") or not player_inventory.has_item(required_item_id, required_amount):
		print("[Intercambio] El jugador no tiene '", required_item_id, "' x", required_amount, " para el intercambio")
		if single_use:
			_close()
		return

	# Quitar el objeto requerido al jugador.
	var removed: bool = false
	if player_inventory.has_method("remove_item"):
		removed = player_inventory.remove_item(required_item_id, required_amount)
	elif player_inventory.has_method("send_item"):
		removed = player_inventory.send_item(required_item_id, required_amount)

	if not removed:
		print("[Intercambio] No se pudo retirar '", required_item_id, "' del inventario del jugador")
		if single_use:
			_close()
		return

	print("[Intercambio] Jugador entregó '", required_item_id, "' x", required_amount)

	# Dar el objeto de recompensa al jugador (si existe).
	if reward_item_id.strip_edges() != "":
		var given: bool = false
		if player_inventory.has_method("receive_item"):
			given = player_inventory.receive_item(reward_item_id, reward_amount)
		elif player_inventory.has_method("add_item"):
			given = player_inventory.add_item(reward_item_id, reward_amount)

		if given:
			print("[Intercambio] Jugador recibió '", reward_item_id, "' x", reward_amount)
		else:
			print("[Intercambio] No se pudo entregar '", reward_item_id, "' al jugador")
	else:
		print("[Intercambio] Sin recompensa configurada (modo ofrenda)")

	_exchange_done = true

	if single_use:
		_close()


# Cierra el contenedor volviendo al estado CLOSED.
func _close() -> void:
	if state_machine != null:
		state_machine.change_to(closed_state_path)


# Busca el `PlayerInventory` del jugador que abrió el cofre.
func _get_player_inventory() -> Node:
	var player_node := _player_node
	if player_node == null:
		player_node = _get_interacting_player()
	if player_node == null:
		push_warning("ContainerOpenIntercambio: jugador interactuando no encontrado")
		return null
	var inventory := player_node.get_node_or_null(player_inventory_path)
	if inventory == null:
		push_warning("ContainerOpenIntercambio: PlayerInventory no encontrado -> " + str(player_inventory_path))
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
		push_warning("ContainerOpenIntercambio: Area2D no encontrado en " + str(interaction_area_path))
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
