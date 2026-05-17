## CofreClosed
# Estado cerrado del cofre.
#
# Mantiene la animación de cerrado, detecta si el jugador está en rango
# del `Area2D` y, al interactuar, guarda una referencia al jugador para
# que el estado abierto pueda transferirle el contenido del contenedor.
extends "res://scripts/interactive/Contenedores/cofre_state_base.gd"

# Clave de metadata usada para recordar qué jugador abrió el contenedor.
const _INTERACTING_PLAYER_META_KEY: StringName = &"cofre_interacting_player"

# Acción de input usada para interactuar con el cofre.
@export var interaction_action: StringName = &"interact"
# Estado al que se cambiará cuando el jugador abra el contenedor.
@export var open_state_path: NodePath = NodePath("CofreOpen")
# Ruta al `Area2D` que detecta al jugador.
@export var interaction_area_path: NodePath = GameConstants.node_container_interaction_area()
# Ruta al sprite animado del contenedor.
@export var animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")

# Grupo y nombre de área usados para reconocer al player.
@export var player_group: StringName = GameConstants.group_player()
@export var player_interact_area_name: StringName = GameConstants.node_player_interact_area_name()

# Referencia al área de interacción ya resuelta.
var _interaction_area: Area2D = null
# Indica si el jugador está actualmente dentro del rango de interacción.
var _player_in_range: bool = false
# Referencia temporal al jugador detectado en el área.
var _player_node: Node = null


# Reinicia banderas, deja el cofre cerrado y conecta las señales del área.
func start() -> void:
	_player_in_range = false
	_player_node = null
	_set_interacting_player(null)
	_play_container_animation(&"Cerrado")
	_bind_interaction_area_signals()


# Al salir del estado se limpian las señales del área.
func end() -> void:
	_unbind_interaction_area_signals()


# Escucha la acción de interacción para abrir el contenedor.
func on_unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return

	if event.is_action_pressed(interaction_action):
		_set_interacting_player(_player_node)
		if state_machine != null:
			state_machine.change_to(open_state_path)


# Resuelve el `Area2D` y conecta las señales de entrada/salida del jugador.
func _bind_interaction_area_signals() -> void:
	if controlled_node == null:
		return

	_interaction_area = controlled_node.get_node_or_null(interaction_area_path) as Area2D
	if _interaction_area == null:
		push_warning("CofreClosed: Area2D no encontrado en " + str(interaction_area_path))
		return

	_interaction_area.monitoring = true
	_interaction_area.monitorable = true

	if not _interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		_interaction_area.area_entered.connect(_on_interaction_area_entered)

	if not _interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		_interaction_area.area_exited.connect(_on_interaction_area_exited)


# Desconecta las señales previamente enlazadas al área de interacción.
func _unbind_interaction_area_signals() -> void:
	if _interaction_area == null:
		return

	if _interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		_interaction_area.area_entered.disconnect(_on_interaction_area_entered)

	if _interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		_interaction_area.area_exited.disconnect(_on_interaction_area_exited)


# Marca al jugador como disponible para abrir el contenedor.
func _on_interaction_area_entered(area: Area2D) -> void:
	if _is_player_interaction_area(area):
		_player_in_range = true
		_player_node = _resolve_player_from_area(area)
		_set_interacting_player(_player_node)


# Limpia la referencia cuando el jugador sale del rango de interacción.
func _on_interaction_area_exited(area: Area2D) -> void:
	if _is_player_interaction_area(area):
		_player_in_range = false
		_player_node = null
		_set_interacting_player(null)


# Determina si el `Area2D` entrante pertenece al jugador.
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


# Reproduce la animación correspondiente del sprite del contenedor.
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


# A partir del área detectada intenta resolver el nodo raíz del jugador.
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


# Guarda o limpia en metadata la referencia al jugador interactuante.
func _set_interacting_player(player_node: Node) -> void:
	if controlled_node == null:
		return

	if player_node == null:
		if controlled_node.has_meta(_INTERACTING_PLAYER_META_KEY):
			controlled_node.remove_meta(_INTERACTING_PLAYER_META_KEY)
		return

	controlled_node.set_meta(_INTERACTING_PLAYER_META_KEY, player_node)
