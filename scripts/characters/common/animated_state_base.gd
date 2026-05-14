# AnimatedCharacterStateBase: base común para estados de personajes con animación.
# Centraliza nombres de animación y helpers reutilizables para NPC, enemigo y player.
class_name AnimatedCharacterStateBase extends Node

const ANIMATION_IDLE: String = "Espera"
const ANIMATION_UP: String = "Arriba"
const ANIMATION_DOWN: String = "Abajo"
const ANIMATION_LEFT: String = "Izquierda"
const ANIMATION_RIGHT: String = "Derecha"

# Nodo controlado por este estado (normalmente el owner de la máquina de estados).
@onready var controlled_node: Node = self.owner


# Reproduce una animación del `AnimatedSprite2D` controlado por el estado.
# Las subclases pueden sobrescribir `_resolve_animation_name` y `_should_skip_animation`
# para ajustar fallback o evitar reinicios innecesarios.
func _play_animation(animation_player_path: NodePath, animation_name: String, force: bool = false) -> void:
	var anim_sprite := _get_animated_sprite(animation_player_path)
	if anim_sprite == null:
		return

	var target_animation := _resolve_animation_name(anim_sprite, animation_name)
	if target_animation == StringName():
		return

	if _should_skip_animation(anim_sprite, target_animation, force):
		return

	anim_sprite.play(target_animation)


# Convierte una dirección de movimiento al nombre de animación correspondiente.
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


# Reproduce automáticamente la animación basada en la dirección dada.
func _play_animation_by_direction(animation_player_path: NodePath, direction: Vector2, threshold: float = 0.5, force: bool = false) -> void:
	var animation_name := _get_animation_by_direction(direction, threshold)
	_play_animation(animation_player_path, animation_name, force)


func _get_animated_sprite(animation_player_path: NodePath) -> AnimatedSprite2D:
	if controlled_node == null:
		return null
	return controlled_node.get_node_or_null(animation_player_path) as AnimatedSprite2D


# Resuelve el nombre efectivo de animación a reproducir.
# Las subclases pueden sobrescribirlo para aplicar fallback o validaciones extra.
func _resolve_animation_name(anim_sprite: AnimatedSprite2D, animation_name: String) -> StringName:
	if anim_sprite.sprite_frames == null:
		return StringName()

	var target_animation := StringName(animation_name)
	if not anim_sprite.sprite_frames.has_animation(target_animation) or anim_sprite.sprite_frames.get_frame_count(target_animation) == 0:
		return StringName()

	return target_animation


# Decide si la reproducción debe omitirse.
# Las subclases pueden sobrescribirlo para evitar reinicios innecesarios o respetar `force`.
func _should_skip_animation(anim_sprite: AnimatedSprite2D, target_animation: StringName, force: bool) -> bool:
	_ = anim_sprite
	_ = target_animation
	_ = force
	return false
