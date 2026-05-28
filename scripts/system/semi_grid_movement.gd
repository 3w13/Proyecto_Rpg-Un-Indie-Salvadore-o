class_name SemiGridMovement extends RefCounted

const DEFAULT_PHYSICS_TICKS_PER_SECOND: float = 60.0
const DEFAULT_MOVEMENT_SEGMENT_PX: float = 8.0
const MIN_SEGMENT_PX: float = 0.001

static var _physics_ticks_per_second_cache: float = -1.0


static func get_physics_ticks_per_second() -> float:
	if _physics_ticks_per_second_cache > 0.0:
		return _physics_ticks_per_second_cache

	_physics_ticks_per_second_cache = float(ProjectSettings.get_setting(
		"physics/common/physics_ticks_per_second",
		DEFAULT_PHYSICS_TICKS_PER_SECOND
	))
	return _physics_ticks_per_second_cache


static func direction_to_velocity(direction: Vector2, movement_segment_px: float = DEFAULT_MOVEMENT_SEGMENT_PX) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction.normalized() * movement_segment_px * get_physics_ticks_per_second()


static func resolve_segment_px(movement_segment_px: float, legacy_speed: float = 0.0) -> float:
	if movement_segment_px > 0.0:
		return movement_segment_px
	if legacy_speed <= 0.0:
		return DEFAULT_MOVEMENT_SEGMENT_PX
	return max(legacy_speed / get_physics_ticks_per_second(), MIN_SEGMENT_PX)
