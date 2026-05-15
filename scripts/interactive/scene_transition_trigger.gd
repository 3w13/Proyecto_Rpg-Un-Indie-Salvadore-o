## SceneTransitionTrigger
# Trigger reutilizable para cambio de escenas desde un Area2D.
#
# Modos soportados:
# - ON_INTERACT: requiere jugador en rango + tecla de interacción.
# - ON_ENTER: solo requiere que el jugador entre al área.
extends Area2D

class_name SceneTransitionTrigger

enum TransitionMode {
    ON_INTERACT,
    ON_ENTER,
}

enum TriggerState {
    IDLE,
    PLAYER_IN_RANGE,
    COOLDOWN,
}

@export var next_scene_path: String = ""
@export var transition_mode: TransitionMode = TransitionMode.ON_INTERACT
@export var interaction_action: StringName = &"interact"
@export var player_group: StringName = &"player"
@export var fallback_player_node_name: StringName = &"Player"
@export var fallback_player_interact_area_name: StringName = &"InteractArea"
@export_range(0.0, 10.0, 0.1) var cooldown: float = 0.5

var _current_state: TriggerState = TriggerState.IDLE
var _player_in_range: bool = false


func _ready() -> void:
    monitoring = true
    monitorable = true

    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)
    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited)

    if not area_entered.is_connected(_on_area_entered):
        area_entered.connect(_on_area_entered)
    if not area_exited.is_connected(_on_area_exited):
        area_exited.connect(_on_area_exited)

    _set_state(TriggerState.IDLE)


func _unhandled_input(event: InputEvent) -> void:
    if transition_mode != TransitionMode.ON_INTERACT:
        return

    if _current_state != TriggerState.PLAYER_IN_RANGE:
        return

    if event.is_action_pressed(interaction_action):
        _request_scene_change()


func _on_body_entered(body: Node2D) -> void:
    if not _is_player_body(body):
        return

    _set_player_in_range(true)

    if transition_mode == TransitionMode.ON_ENTER:
        _request_scene_change()


func _on_body_exited(body: Node2D) -> void:
    if not _is_player_body(body):
        return

    _set_player_in_range(false)


func _on_area_entered(area: Area2D) -> void:
    if not _is_player_interaction_area(area):
        return

    _set_player_in_range(true)

    if transition_mode == TransitionMode.ON_ENTER:
        _request_scene_change()


func _on_area_exited(area: Area2D) -> void:
    if not _is_player_interaction_area(area):
        return

    _set_player_in_range(false)


func _request_scene_change() -> void:
    if _current_state == TriggerState.COOLDOWN:
        return

    if next_scene_path.strip_edges() == "":
        push_warning("SceneTransitionTrigger: next_scene_path vacío en " + name)
        return

    _set_state(TriggerState.COOLDOWN)

    var result := get_tree().change_scene_to_file(next_scene_path)
    if result == OK:
        return

    push_warning("SceneTransitionTrigger: no se pudo cambiar a '%s' (error: %s)" % [next_scene_path, str(result)])
    await _run_cooldown()
    if _player_in_range:
        _set_state(TriggerState.PLAYER_IN_RANGE)
    else:
        _set_state(TriggerState.IDLE)


func _run_cooldown() -> void:
    if cooldown <= 0.0:
        return

    await get_tree().create_timer(cooldown).timeout


func _set_state(new_state: TriggerState) -> void:
    _current_state = new_state


func _set_player_in_range(in_range: bool) -> void:
    _player_in_range = in_range
    if _current_state == TriggerState.COOLDOWN:
        return

    if _player_in_range:
        _set_state(TriggerState.PLAYER_IN_RANGE)
    else:
        _set_state(TriggerState.IDLE)


func _is_player_body(body: Node) -> bool:
    if body == null:
        return false

    if body.is_in_group(player_group):
        return true

    if fallback_player_node_name != &"" and body.name == String(fallback_player_node_name):
        return true

    var owner_node := body.owner
    if owner_node != null and owner_node.is_in_group(player_group):
        return true

    var parent_node := body.get_parent()
    if parent_node != null and parent_node.is_in_group(player_group):
        return true

    return false


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

    if fallback_player_interact_area_name != &"" and area.name == String(fallback_player_interact_area_name):
        return true

    return false
