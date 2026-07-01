## PlayerInventory
# Nodo responsable de almacenar los objetos del jugador.
#
# Este inventario no depende de la UI ni de un estado concreto.
# Los estados del player y otros sistemas externos pueden consultarlo
# y modificarlo mediante su API pública.
extends Node


#region Constantes

# Ruta al archivo .dialogue usado para mostrar mensajes de item recibido.
const _ITEM_RECEIVED_DIALOGUE: String = "res://dialogues/mensajes de intefaz/Objetos_recojidos.dialogue"

#endregion


#region Variables

# Diccionario principal del inventario.
# Formato esperado: { "nombre_objeto": cantidad }
var items: Dictionary = {}

# Datos del último lote de objetos recibidos.
# Usados por el diálogo de notificación para construir el mensaje.
var last_received_item: String = ""
var last_received_amount: int = 0
var last_received_items_text: String = ""

#endregion


#region API pública

# Alias semántico para recibir un único objeto desde otros sistemas.
func receive_item(item_id: String, amount: int = 1) -> bool:
	return receive_items({item_id: amount})


# Recibe uno o varios objetos y muestra una sola notificación agregada.
# Formato esperado: { "nombre_objeto": cantidad }
# Ignora entradas con item_id vacío o cantidad <= 0 y avisa en consola.
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

		# Acumular en caso de que el mismo item_id aparezca más de una vez.
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


# Alias semántico para quitar objetos del inventario.
func send_item(item_id: String, amount: int = 1) -> bool:
	return remove_item(item_id, amount)


# Alias de receive_items para añadir objetos sin mostrar diálogo de notificación.
# Internamente delega en receive_items, que sí muestra el balloon.
func add_item(item_id: String, amount: int = 1) -> bool:
	return receive_items({item_id: amount})


# Elimina una cantidad de un objeto si existe suficiente stock.
# Devuelve false sin modificar el inventario si el stock es insuficiente.
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
	# Si llega a 0, eliminar la entrada del diccionario para mantenerlo limpio.
	if updated_amount <= 0:
		items.erase(item_id)
	else:
		items[item_id] = updated_amount

	print("[Inventario] -", amount, " ", item_id)
	print_inventory()
	return true


# Verifica si el inventario tiene al menos la cantidad solicitada de un objeto.
func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount


# Devuelve la cantidad actual de un objeto concreto. Retorna 0 si no existe.
func get_item_count(item_id: String) -> int:
	if item_id.strip_edges() == "":
		return 0
	return int(items.get(item_id, 0))


# Devuelve una copia profunda del inventario para evitar modificaciones externas accidentales.
func get_all_items() -> Dictionary:
	return items.duplicate(true)


# Vacía el inventario por completo.
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

#endregion


#region Utilidades internas

# Construye los campos de último lote recibido para reutilizarlos en el diálogo.
# Si se recibió un solo tipo de objeto, rellena last_received_item y last_received_amount.
# Si se recibieron varios, deja esos campos vacíos y usa last_received_items_text.
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
		# Lote de varios objetos: no tiene sentido exponer un único item.
		last_received_item = ""
		last_received_amount = 0


# Muestra el balloon de notificación de objeto recibido usando DialogueManager.
# Si el singleton o el recurso no están disponibles, falla silenciosamente.
func _show_item_received_dialogue() -> void:
	var dm := Engine.get_singleton("DialogueManager")
	if dm == null:
		return

	var resource: Resource = load(_ITEM_RECEIVED_DIALOGUE)
	if resource == null:
		push_warning("PlayerInventory: no se encontró el diálogo " + _ITEM_RECEIVED_DIALOGUE)
		return

	dm.show_dialogue_balloon(resource, "start", [self])

#endregion
