# StateBase: clase base que deben extender todos los estados del player.
# Extiende la base común de animación y añade lógica específica del jugador.
class_name StateBase extends AnimatedCharacterStateBase

const _FACING_META_KEY: StringName = &"player_facing_direction"

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
func _resolve_animation_name(anim_sprite: AnimatedSprite2D, animation_name: String) -> StringName:
	if anim_sprite.sprite_frames == null:
		return StringName()

	var target_animation := StringName(animation_name)
	if not anim_sprite.sprite_frames.has_animation(target_animation) or anim_sprite.sprite_frames.get_frame_count(target_animation) == 0:
		target_animation = StringName(ANIMATION_IDLE)
		if not anim_sprite.sprite_frames.has_animation(target_animation) or anim_sprite.sprite_frames.get_frame_count(target_animation) == 0:
			return StringName()

	return target_animation


func _should_skip_animation(anim_sprite: AnimatedSprite2D, target_animation: StringName, force: bool) -> bool:
	return not force and anim_sprite.animation == target_animation and anim_sprite.is_playing()


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
