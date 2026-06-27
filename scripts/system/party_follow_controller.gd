class_name PartyFollowController
extends CharacterBody2D

const FOLLOWER_ORDER: PackedStringArray = ["ChibiBrown", "ChibiBlue", "ChibiPurple"]
const FACING_META_KEY: StringName = &"player_facing_direction"
const ANIMATION_IDLE := &"Espera"
const ANIMATION_UP := &"Arriba"
const ANIMATION_DOWN := &"Abajo"
const ANIMATION_LEFT := &"Izquierda"
const ANIMATION_RIGHT := &"Derecha"

@export_group("Party")
@export_range(1, 60, 1) var trail_frame_spacing: int = 12
@export_range(0.0, 64.0, 0.5) var stop_distance: float = 10.0
@export_range(0.0, 64.0, 0.5) var resume_distance: float = 18.0
@export_range(1.0, 3.0, 0.05) var catch_up_multiplier: float = 1.15
@export_range(0.5, 32.0, 0.5) var min_record_distance: float = 6.0

@export_group("Referencias")
@export var animation_player_path: NodePath = NodePath("AnimatedSprite2D")
@export var follower_state_machine_path: NodePath = NodePath("StateMachine")

var _followers: Array[Dictionary] = []
var _trail: Array[Dictionary] = []
var _last_global_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_last_global_position = global_position
	_initialize_followers()
	_seed_trail()


func _physics_process(_delta: float) -> void:
	if _followers.is_empty():
		return

	_record_trail_point()

	for follower_index in _followers.size():
		_update_follower(_followers[follower_index], follower_index)

	_trim_trail()


func _initialize_followers() -> void:
	_followers.clear()
	var parent_node := get_parent()
	if parent_node == null:
		return

	for follower_name in FOLLOWER_ORDER:
		var follower_body := parent_node.get_node_or_null(NodePath(String(follower_name))) as CharacterBody2D
		if follower_body == null or follower_body == self:
			continue

		var follower_state_machine := follower_body.get_node_or_null(follower_state_machine_path) as Node
		if follower_state_machine == null:
			continue

		if follower_state_machine.has_method("set_party_follower"):
			follower_state_machine.set_party_follower(true)
		if follower_state_machine.has_method("set_party_follow_parameters"):
			follower_state_machine.set_party_follow_parameters(stop_distance, resume_distance, catch_up_multiplier)

		_followers.append({
			"body": follower_body,
			"state_machine": follower_state_machine,
		})


func _seed_trail() -> void:
	_trail.clear()
	var facing_direction := _get_facing_direction(self)
	for _index in range(_required_trail_size()):
		_trail.append(_build_trail_point(global_position, facing_direction))


func _record_trail_point() -> void:
	var movement := global_position - _last_global_position
	if movement.length() < min_record_distance:
		return

	var facing_direction := movement.normalized()
	if facing_direction == Vector2.ZERO:
		return

	_set_facing_direction(self, facing_direction)
	_trail.append(_build_trail_point(global_position, facing_direction))
	_last_global_position = global_position


func _update_follower(follower_data: Dictionary, follower_index: int) -> void:
	var follower_body := follower_data.get("body") as CharacterBody2D
	if follower_body == null or not is_instance_valid(follower_body):
		return
	var follower_state_machine := follower_data.get("state_machine") as Node
	if follower_state_machine == null or not is_instance_valid(follower_state_machine):
		return

	var trail_offset := (follower_index + 1) * trail_frame_spacing
	var trail_index := maxi(0, _trail.size() - 1 - trail_offset)
	var target_point: Dictionary = _trail[trail_index]
	var target_position := target_point.get("position", follower_body.global_position) as Vector2
	var target_facing := target_point.get("facing", Vector2.DOWN) as Vector2
	var leader_speed := velocity.length()
	var leader_is_moving := leader_speed > 0.1
	if follower_state_machine.has_method("set_follow_target"):
		follower_state_machine.set_follow_target(target_position, target_facing, leader_speed, leader_is_moving)


func _trim_trail() -> void:
	var max_points := _required_trail_size()
	if _trail.size() <= max_points:
		return

	_trail = _trail.slice(_trail.size() - max_points, _trail.size())


func _required_trail_size() -> int:
	return ((FOLLOWER_ORDER.size() + 1) * trail_frame_spacing) + 12


func _build_trail_point(target_position: Vector2, facing_direction: Vector2) -> Dictionary:
	return {
		"position": target_position,
		"facing": facing_direction if facing_direction != Vector2.ZERO else Vector2.DOWN,
	}


func _set_facing_direction(target_body: CharacterBody2D, direction: Vector2) -> void:
	if target_body == null or direction == Vector2.ZERO:
		return
	target_body.set_meta(FACING_META_KEY, direction.normalized())


func _get_facing_direction(target_body: CharacterBody2D) -> Vector2:
	if target_body == null:
		return Vector2.DOWN
	if target_body.has_meta(FACING_META_KEY):
		var stored_direction: Variant = target_body.get_meta(FACING_META_KEY)
		if stored_direction is Vector2 and stored_direction != Vector2.ZERO:
			return (stored_direction as Vector2).normalized()
	return Vector2.DOWN
