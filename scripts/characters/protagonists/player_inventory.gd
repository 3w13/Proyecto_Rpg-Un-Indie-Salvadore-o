## PlayerInventory
# Nodo responsable de almacenar los objetos del jugador.
#
# Este inventario no depende de la UI ni de un estado concreto.
# Los estados del player y otros sistemas externos pueden consultarlo
# y modificarlo mediante su API pública.
extends Node

# Ruta al archivo .dialogue usado para mostrar mensajes de item recibido.
const _ITEM_RECEIVED_DIALOGUE: String = "res://dialogues/mensajes de intefaz/Objetos_recojidos.dialogue"

# Diccionario principal del inventario.
# Formato esperado: {"nombre_objeto": cantidad}
var items: Dictionary = {}

# Último item recibido. Usado por el diálogo de notificación.
var last_received_item: String = ""
# Última cantidad recibida. Usado por el diálogo de notificación.
var last_received_amount: int = 0
# Texto agregado de los últimos objetos recibidos. Usado por el diálogo de notificación.
var last_received_items_text: String = ""


# Alias semántico para recibir objetos desde otros sistemas.
func receive_item(item_id: String, amount: int = 1) -> bool:
	return receive_items({item_id: amount})


# Recibe uno o varios objetos y muestra una sola notificación agregada.
# Formato esperado: {"nombre_objeto": cantidad}
func receive_items(received_items: Dictionary) -> bool:
	if received_items.is_empty():
		push_warning("PlayerInventory: receive_items recibió un diccionario vacío")
		return false

	var normalized_items: Dictionary = {}
	for key in received_items.keys():
		var item_id := String(key).strip_edges()
		var amount := int(received_items[key])

		if item_id == "":
			push_warning("PlayerInventory: item_id vacío en receive_items")
			continue

		if amount <= 0:
			push_warning("PlayerInventory: amount debe ser mayor a 0 para " + item_id)
			continue

		normalized_items[item_id] = int(normalized_items.get(item_id, 0)) + amount

	if normalized_items.is_empty():
		push_warning("PlayerInventory: receive_items no recibió objetos válidos")
		return false

	for item_id in normalized_items.keys():
		var amount := int(normalized_items[item_id])
		items[item_id] = int(items.get(item_id, 0)) + amount
		print("[Inventario] +", amount, " ", item_id)

	_update_last_received_data(normalized_items)
	_show_item_received_dialogue()
	print_inventory()
	return true


# Alias semántico para entregar/quitar objetos del inventario.
func send_item(item_id: String, amount: int = 1) -> bool:
	return remove_item(item_id, amount)


# Agrega una cantidad de un objeto al inventario del jugador.
func add_item(item_id: String, amount: int = 1) -> bool:
	return receive_items({item_id: amount})


# Elimina una cantidad de un objeto si existe suficiente stock.
func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_id.strip_edges() == "":
		push_warning("PlayerInventory: item_id vacío")
		return false

	if amount <= 0:
		push_warning("PlayerInventory: amount debe ser mayor a 0")
		return false

	var current_amount := int(items.get(item_id, 0))
	if current_amount < amount:
		print("[Inventario] No se pudo quitar ", amount, " ", item_id, " (disponible: ", current_amount, ")")
		return false

	var updated_amount := current_amount - amount
	if updated_amount <= 0:
		items.erase(item_id)
	else:
		items[item_id] = updated_amount

	print("[Inventario] -", amount, " ", item_id)
	print_inventory()
	return true


# Verifica si el inventario tiene al menos la cantidad solicitada.
func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount


# Devuelve la cantidad actual de un objeto concreto.
func get_item_count(item_id: String) -> int:
	if item_id.strip_edges() == "":
		return 0

	return int(items.get(item_id, 0))


# Devuelve una copia segura de todos los objetos almacenados.
func get_all_items() -> Dictionary:
	return items.duplicate(true)


# Borra por completo el contenido del inventario.
func clear_inventory() -> void:
	items.clear()
	print("[Inventario] Limpiado")
	print_inventory()


# Imprime el contenido actual del inventario en consola.
func print_inventory() -> void:
	if items.is_empty():
		print("[Inventario] Vacío")
		return

	print("[Inventario] Objetos actuales: ", items)


# Construye los campos de último loot para mostrar un mensaje único y reutilizable.
func _update_last_received_data(received_items: Dictionary) -> void:
	var sorted_item_ids: Array = received_items.keys()
	sorted_item_ids.sort()

	last_received_items_text = ""
	for index in sorted_item_ids.size():
		var item_id := String(sorted_item_ids[index])
		var amount := int(received_items[item_id])

		if index > 0:
			last_received_items_text += ", "
		last_received_items_text += "%s x%d" % [item_id, amount]

	if sorted_item_ids.size() == 1:
		last_received_item = String(sorted_item_ids[0])
		last_received_amount = int(received_items[last_received_item])
	else:
		last_received_item = ""
		last_received_amount = 0


# Muestra el balloon de notificación usando DialogueManager.
func _show_item_received_dialogue() -> void:
	var dm := Engine.get_singleton("DialogueManager")
	if dm == null:
		return

	var resource: Resource = load(_ITEM_RECEIVED_DIALOGUE)
	if resource == null:
		push_warning("PlayerInventory: no se encontró el diálogo " + _ITEM_RECEIVED_DIALOGUE)
		return

	dm.show_dialogue_balloon(resource, "start", [self])
