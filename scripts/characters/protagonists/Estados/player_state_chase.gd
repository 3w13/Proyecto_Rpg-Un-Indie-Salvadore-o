extends StateBase

@export var speed: float = 250.0
@export var animation_player_path: NodePath = "AnimatedSprite2D"


func start() -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return

	player.velocity = Vector2.ZERO


func on_physics_process(delta: float) -> void:
	var player := controlled_node as CharacterBody2D
	if player == null:
		return
	if state_machine == null:
		return
	if not state_machine.has_method("has_follow_target"):
		return

	if not state_machine.has_follow_target():
		_change_to_idle(player)
		return

	var target_position: Vector2 = state_machine.get_follow_target_position()
	var to_target := target_position - player.global_position
	var distance_to_target := to_target.length()
	if state_machine.has_method("should_stop_chase") and state_machine.should_stop_chase(player.global_position):
		_change_to_idle(player)
		return

	if distance_to_target <= 0.001:
		_change_to_idle(player)
		return

	var move_direction := to_target.normalized()
	var catch_up_multiplier := 1.0
	if state_machine.has_method("get_party_catch_up_multiplier"):
		catch_up_multiplier = state_machine.get_party_catch_up_multiplier()
	var target_facing := _get_facing_direction()
	if state_machine.has_method("get_follow_target_facing"):
		target_facing = state_machine.get_follow_target_facing()
	var target_speed := 0.0
	if state_machine.has_method("get_follow_target_speed"):
		target_speed = state_machine.get_follow_target_speed()
	var target_is_moving := false
	if state_machine.has_method("is_follow_target_moving"):
		target_is_moving = state_machine.is_follow_target_moving()
	var max_frame_speed := distance_to_target / maxf(delta, 0.001)
	var follow_speed := _resolve_follow_speed(distance_to_target, target_speed, target_is_moving, catch_up_multiplier)
	var applied_speed := minf(follow_speed, max_frame_speed)
	var animation_direction := _resolve_cardinal_direction(move_direction, target_facing)

	_set_facing_direction(animation_direction)
	player.velocity = move_direction * applied_speed
	_play_animation_by_direction(animation_player_path, animation_direction)
	player.move_and_slide()


func _change_to_idle(player: CharacterBody2D) -> void:
	if state_machine != null and state_machine.has_method("get_follow_target_facing"):
		var target_facing: Vector2 = state_machine.get_follow_target_facing()
		if target_facing != Vector2.ZERO:
			_set_facing_direction(_resolve_cardinal_direction(target_facing, target_facing))
	player.velocity = Vector2.ZERO
	player.move_and_slide()
	_play_animation(animation_player_path, ANIMATION_IDLE_DOWN, true)
	state_machine.change_to("PlayerStateIdle")


func _resolve_follow_speed(distance_to_target: float, target_speed: float, target_is_moving: bool, catch_up_multiplier: float) -> float:
	var stop_distance := 10.0
	if state_machine != null and state_machine.has_method("get_party_stop_distance"):
		stop_distance = state_machine.get_party_stop_distance()
	var resume_distance := maxf(stop_distance + 1.0, 18.0)
	if state_machine != null and state_machine.has_method("get_party_resume_distance"):
		resume_distance = maxf(state_machine.get_party_resume_distance(), stop_distance + 1.0)

	var gap_ratio := clampf((distance_to_target - stop_distance) / maxf(resume_distance - stop_distance, 0.001), 0.0, 1.0)
	if target_is_moving:
		var near_speed := maxf(minf(speed * 0.8, target_speed * 0.9), 80.0)
		var far_speed := maxf(speed, target_speed * catch_up_multiplier)
		return lerpf(near_speed, far_speed, gap_ratio)

	var near_settle_speed := maxf(speed * 0.45, 70.0)
	var far_settle_speed := maxf(speed * 0.8, near_settle_speed)
	return lerpf(near_settle_speed, far_settle_speed, gap_ratio)


func _resolve_cardinal_direction(move_direction: Vector2, preferred_direction: Vector2 = Vector2.ZERO) -> Vector2:
	if move_direction == Vector2.ZERO:
		if preferred_direction != Vector2.ZERO:
			return _resolve_cardinal_direction(preferred_direction)
		return _get_facing_direction()

	var normalized_direction := move_direction.normalized()
	var abs_x := absf(normalized_direction.x)
	var abs_y := absf(normalized_direction.y)
	if preferred_direction != Vector2.ZERO:
		var preferred_cardinal := _resolve_cardinal_direction(preferred_direction)
		if absf(abs_x - abs_y) <= 0.15:
			return preferred_cardinal
	if is_equal_approx(abs_x, abs_y):
		var stored_direction := _get_facing_direction()
		if absf(stored_direction.x) > absf(stored_direction.y):
			return Vector2(signf(stored_direction.x), 0.0)
		if absf(stored_direction.y) > 0.0:
			return Vector2(0.0, signf(stored_direction.y))

	if abs_x > abs_y:
		return Vector2(signf(normalized_direction.x), 0.0)

	return Vector2(0.0, signf(normalized_direction.y))