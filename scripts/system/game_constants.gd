class_name GameConstants extends RefCounted

const GROUP_PLAYER: StringName = &"player"
const GROUP_ENEMY: StringName = &"enemy"
const GROUP_NPC: StringName = &"npc"
const GROUP_CONTAINER: StringName = &"container"
const GROUP_INTERACTABLE: StringName = &"interactable"

const PHYSICS_LAYER_WORLD: int = 1
const PHYSICS_LAYER_CHARACTER_BODY: int = 1 << 1
const PHYSICS_MASK_WORLD_ONLY: int = PHYSICS_LAYER_WORLD
const PHYSICS_MASK_PLAYER_PRESENCE: int = PHYSICS_LAYER_WORLD | PHYSICS_LAYER_CHARACTER_BODY

const NODE_PLAYER_STATE_MACHINE: NodePath = NodePath("StateMachine")
const NODE_PLAYER_ROOT_NAME: StringName = &"Player"
const NODE_PLAYER_INTERACT_AREA_NAME: StringName = &"InteractArea"
const NODE_ENEMY_DETECTION_AREA: NodePath = NodePath("DetectionArea")
const NODE_NPC_INTERACTION_AREA: NodePath = NodePath("InteractionArea")
const NODE_CONTAINER_INTERACTION_AREA: NodePath = NodePath("Area2D")


static func group_player() -> StringName:
	return GROUP_PLAYER


static func physics_layer_world() -> int:
	return PHYSICS_LAYER_WORLD


static func physics_layer_character_body() -> int:
	return PHYSICS_LAYER_CHARACTER_BODY


static func physics_mask_world_only() -> int:
	return PHYSICS_MASK_WORLD_ONLY


static func physics_mask_player_presence() -> int:
	return PHYSICS_MASK_PLAYER_PRESENCE


static func node_player_state_machine() -> NodePath:
	return NODE_PLAYER_STATE_MACHINE


static func node_player_root_name() -> StringName:
	return NODE_PLAYER_ROOT_NAME


static func node_enemy_detection_area() -> NodePath:
	return NODE_ENEMY_DETECTION_AREA


static func node_player_interact_area_name() -> StringName:
	return NODE_PLAYER_INTERACT_AREA_NAME


static func node_npc_interaction_area() -> NodePath:
	return NODE_NPC_INTERACTION_AREA


static func node_container_interaction_area() -> NodePath:
	return NODE_CONTAINER_INTERACTION_AREA