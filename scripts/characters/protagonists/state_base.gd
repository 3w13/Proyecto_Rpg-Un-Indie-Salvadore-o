# StateBase: clase base que deben extender todos los estados.
# Define el contrato común: propiedades compartidas y métodos virtuales.
# Los estados concretos sobreescriben solo los métodos que necesitan.
class_name StateBase extends Node

const ANIMATION_IDLE: String = "Espera"
const ANIMATION_UP: String = "Arriba"
const ANIMATION_DOWN: String = "Abajo"
const ANIMATION_LEFT: String = "Izquierda"
const ANIMATION_RIGHT: String = "Derecha"

const _FACING_META_KEY: StringName = &"player_facing_direction"

# Nodo que este estado controla (asignado por StateMachine al activarse).
@onready var controlled_node:Node = self.owner

# Referencia a la máquina de estados para poder pedir cambios de estado
# con state_machine.change_to("NombreEstado").
# Tipo real: PlayerStateMachine (tipado como Node para evitar dependencia circular).
var state_machine: Node

#region Métodos virtuales — sobreescribir en cada estado concreto

# Se llama una vez al activarse el estado.
func start():
	pass

# Se llama una vez al desactivarse el estado (antes del siguiente start).
func end():
	pass


# Reproduce una animación del `AnimatedSprite2D` del player con fallback a `ANIMATION_IDLE`.
func _play_animation(animation_player_path: NodePath, animation_name: String, force: bool = false) -> void:
	var anim_sprite := controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D
	if anim_sprite == null:
		return

	if anim_sprite.sprite_frames == null:
		return

	var target_animation := StringName(animation_name)
	if not anim_sprite.sprite_frames.has_animation(target_animation) or anim_sprite.sprite_frames.get_frame_count(target_animation) == 0:
		target_animation = StringName(ANIMATION_IDLE)
		if not anim_sprite.sprite_frames.has_animation(target_animation) or anim_sprite.sprite_frames.get_frame_count(target_animation) == 0:
			return

	if not force and anim_sprite.animation == target_animation and anim_sprite.is_playing():
		return

	anim_sprite.play(target_animation)


# Convierte un vector de dirección en el nombre de animación correspondiente.
func _get_animation_by_direction(direction: Vector2, threshold: float = 0.5) -> String:
	if direction.x < -threshold:
		return ANIMATION_LEFT
	if direction.x > threshold:
		return ANIMATION_RIGHT
	if direction.y < -threshold:
		return ANIMATION_UP
	if direction.y > threshold:
		return ANIMATION_DOWN
	return ANIMATION_IDLE


# Reproduce automáticamente la animación basada en la dirección actual.
func _play_animation_by_direction(animation_player_path: NodePath, direction: Vector2, threshold: float = 0.5, force: bool = false) -> void:
	var animation_name := _get_animation_by_direction(direction, threshold)
	_play_animation(animation_player_path, animation_name, force)


# Guarda en metadata la última dirección válida del player.
func _set_facing_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO or controlled_node == null:
		return
	controlled_node.set_meta(_FACING_META_KEY, direction.normalized())


# Recupera la dirección de facing guardada o devuelve `Vector2.DOWN` por defecto.
func _get_facing_direction() -> Vector2:
	if controlled_node == null:
		return Vector2.DOWN

	if controlled_node.has_meta(_FACING_META_KEY):
		var stored = controlled_node.get_meta(_FACING_META_KEY)
		if stored is Vector2 and stored != Vector2.ZERO:
			return (stored as Vector2).normalized()

	return Vector2.DOWN

#endregion
