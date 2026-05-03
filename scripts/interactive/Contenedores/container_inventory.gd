## ContainerInventory
# Nodo responsable de guardar el contenido interno del cofre/contenedor.
#
# Usa la misma API pública que `PlayerInventory` para facilitar la futura
# transferencia de objetos entre ambos inventarios.
extends Node

# Contenido inicial del contenedor al entrar en escena.
@export var default_items: Dictionary = {
	"Chatara": 1,
	"creditos": 1,
	"cristal ambar": 1,
}

# Diccionario principal del inventario del cofre.
var items: Dictionary = {}


# Inicializa el contenido por defecto si todavía está vacío.
func _ready() -> void:
	if items.is_empty() and not default_items.is_empty():
		items = default_items.duplicate(true)


# Alias semántico para recibir objetos desde otros sistemas.
func receive_item(item_id: String, amount: int = 1) -> bool:
	return add_item(item_id, amount)


# Alias semántico para entregar/quitar objetos del contenedor.
func send_item(item_id: String, amount: int = 1) -> bool:
	return remove_item(item_id, amount)


# Agrega una cantidad de un objeto al inventario del contenedor.
func add_item(item_id: String, amount: int = 1) -> bool:
	if item_id.strip_edges() == "":
		push_warning("ContainerInventory: item_id vacío")
		return false

	if amount <= 0:
		push_warning("ContainerInventory: amount debe ser mayor a 0")
		return false

	items[item_id] = int(items.get(item_id, 0)) + amount
	print("[Contenedor] +", amount, " ", item_id)
	print_inventory()
	return true


# Elimina una cantidad de un objeto del contenedor si existe suficiente stock.
func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_id.strip_edges() == "":
		push_warning("ContainerInventory: item_id vacío")
		return false

	if amount <= 0:
		push_warning("ContainerInventory: amount debe ser mayor a 0")
		return false

	var current_amount := int(items.get(item_id, 0))
	if current_amount < amount:
		print("[Contenedor] No se pudo quitar ", amount, " ", item_id, " (disponible: ", current_amount, ")")
		return false

	var updated_amount := current_amount - amount
	if updated_amount <= 0:
		items.erase(item_id)
	else:
		items[item_id] = updated_amount

	print("[Contenedor] -", amount, " ", item_id)
	print_inventory()
	return true


# Verifica si el contenedor posee al menos la cantidad solicitada.
func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount


# Devuelve la cantidad de un objeto concreto almacenado.
func get_item_count(item_id: String) -> int:
	if item_id.strip_edges() == "":
		return 0

	return int(items.get(item_id, 0))


# Devuelve una copia segura de todos los objetos del contenedor.
func get_all_items() -> Dictionary:
	return items.duplicate(true)


# Borra por completo el contenido interno del contenedor.
func clear_inventory() -> void:
	items.clear()
	print("[Contenedor] Inventario limpiado")
	print_inventory()


# Imprime en consola el contenido actual del contenedor.
func print_inventory() -> void:
	if items.is_empty():
		print("[Contenedor] Vacío")
		return

	print("[Contenedor] Objetos actuales: ", items)
