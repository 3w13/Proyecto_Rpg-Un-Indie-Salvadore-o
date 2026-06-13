## BoxDialogues
# Componente UI reutilizable para mostrar un nombre y una línea de diálogo.
#
# La escena puede instanciarse en cualquier mapa y controlarse mediante su
# API pública sin depender de texto hardcodeado ni de una jerarquía externa.
class_name BoxDialogues
extends CanvasLayer

const NPC_PANEL_KEY := &"npc"
const PLAYER_PANEL_KEY := &"player"

@export_group("Configuración de Diálogo")
@export var dialogue_resource: DialogueResource
@export_file("*.dialogue") var dialogue_path: String = ""
@export_file("*.tscn") var dialogue_balloon_scene_path: String = "res://scenes/ui/Box_Dialogues.tscn"
@export var dialogue_title: String = ""
@export var next_action: StringName = &"ui_accept"
@export var player_speaker_names: PackedStringArray = ["Player", "Jugador", "Prota", "Protagonista"]
@export var player_group_name: StringName = &""

@export_group("Referencias de Nodos")
@export var npc_panel_path: NodePath = NodePath("NpcPanel")
@export var npc_response_container_path: NodePath = NodePath("NpcPanel/MarginContainer/GridContainer")
@export var npc_speaker_label_path: NodePath = NodePath("NpcPanel/MarginContainer/GridContainer/Name")
@export var npc_dialogue_label_path: NodePath = NodePath("NpcPanel/MarginContainer/GridContainer/Dialogue")
@export var player_panel_path: NodePath = NodePath("PlayerPanel")
@export var player_response_container_path: NodePath = NodePath("PlayerPanel/MarginContainer/GridContainer")
@export var player_speaker_label_path: NodePath = NodePath("PlayerPanel/MarginContainer/GridContainer/Name")
@export var player_dialogue_label_path: NodePath = NodePath("PlayerPanel/MarginContainer/GridContainer/Dialogue")
@export var animation_player_path: NodePath = NodePath("AnimationPlayer")

@export_group("Contenido Visual")
@export var default_speaker_name: String = ""
@export_multiline var default_dialogue_text: String = ""
@export var show_on_ready: bool = false
@export var clear_text_on_hide: bool = false
@export var track_target_in_screen: bool = true
@export var npc_side_offset: Vector2 = Vector2(24, 0)
@export var player_side_offset: Vector2 = Vector2(24, 0)
@export var clamp_to_viewport: bool = true
@export var anchor_clearance_radius: float = 48.0
@export_group("Ajuste de Tamaño")
@export var dialogue_panel_min_width: float = 50.0
@export var dialogue_panel_max_width: float = 200.0
@export_group("Animaciones")
@export var npc_enter_animation: StringName = &"Boxdialogues_Npc_Entrada"
@export var npc_exit_animation: StringName = &"Boxdialogues_Npc_Salida"
@export var player_enter_animation: StringName = &"Boxdialogues_Player_Entrada"
@export var player_exit_animation: StringName = &"Boxdialogues_Player_Salida"
@export_range(0.0, 1.0, 0.01) var animation_safety_time: float = 0.08

var _npc_panel: Control = null
var _npc_response_container: Control = null
var _npc_speaker_label: Label = null
var _npc_dialogue_label: Label = null
var _player_panel: Control = null
var _player_response_container: Control = null
var _player_speaker_label: Label = null
var _player_dialogue_label: Label = null
var _current_line: DialogueLine = null
var _temporary_game_states: Array = []
var _is_waiting_for_input: bool = false
var _response_buttons: Array[Button] = []
var _npc_anchor_target: Node2D = null
var _player_anchor_target: Node2D = null
var _active_panel: Control = null
var _active_response_container: Control = null
var _active_speaker_label: Label = null
var _active_dialogue_label: Label = null
var _active_panel_on_right: bool = false
var _npc_left_stylebox: StyleBox = null
var _npc_right_stylebox: StyleBox = null
var _player_left_stylebox: StyleBox = null
var _player_right_stylebox: StyleBox = null
var _npc_panel_fixed_height: float = 0.0
var _player_panel_fixed_height: float = 0.0
var _panel_views: Dictionary = {}
var _active_panel_key: StringName = NPC_PANEL_KEY
var _runtime_dialogue_resource: DialogueResource = null
var _animation_player: AnimationPlayer = null
var _hide_clear_content_requested: bool = false
var _hide_animation_pending: bool = false
var _pending_hide_animation: StringName = &""
var _queue_free_after_hide: bool = false
var _panel_switch_pending: bool = false
var _pending_switch_panel_key: StringName = NPC_PANEL_KEY
var _pending_switch_speaker_name: String = ""
var _pending_switch_dialogue_text: String = ""
var _pending_switch_exit_animation: StringName = &""
var _input_locked_until_msec: int = 0


func _ready() -> void:
	_npc_panel = get_node_or_null(npc_panel_path) as Control
	_npc_response_container = get_node_or_null(npc_response_container_path) as Control
	_npc_speaker_label = get_node_or_null(npc_speaker_label_path) as Label
	_npc_dialogue_label = get_node_or_null(npc_dialogue_label_path) as Label
	_player_panel = get_node_or_null(player_panel_path) as Control
	_player_response_container = get_node_or_null(player_response_container_path) as Control
	_player_speaker_label = get_node_or_null(player_speaker_label_path) as Label
	_player_dialogue_label = get_node_or_null(player_dialogue_label_path) as Label
	_animation_player = get_node_or_null(animation_player_path) as AnimationPlayer

	if _npc_panel == null:
		push_warning("BoxDialogues: no se encontró el panel NPC -> " + str(npc_panel_path))
		return

	if _npc_speaker_label == null:
		push_warning("BoxDialogues: no se encontró la etiqueta de nombre NPC -> " + str(npc_speaker_label_path))

	if _npc_dialogue_label == null:
		push_warning("BoxDialogues: no se encontró la etiqueta de diálogo NPC -> " + str(npc_dialogue_label_path))

	if _npc_response_container == null:
		push_warning("BoxDialogues: no se encontró el contenedor de respuestas NPC -> " + str(npc_response_container_path))

	if _player_panel == null:
		push_warning("BoxDialogues: no se encontró el panel Player -> " + str(player_panel_path))

	if _player_speaker_label == null:
		push_warning("BoxDialogues: no se encontró la etiqueta de nombre Player -> " + str(player_speaker_label_path))

	if _player_dialogue_label == null:
		push_warning("BoxDialogues: no se encontró la etiqueta de diálogo Player -> " + str(player_dialogue_label_path))

	if _player_response_container == null:
		push_warning("BoxDialogues: no se encontró el contenedor de respuestas Player -> " + str(player_response_container_path))

	if _animation_player == null:
		push_warning("BoxDialogues: no se encontró AnimationPlayer -> " + str(animation_player_path))
	elif not _animation_player.animation_finished.is_connected(_on_animation_player_animation_finished):
		_animation_player.animation_finished.connect(_on_animation_player_animation_finished)

	_npc_panel_fixed_height = _npc_panel.size.y if _npc_panel != null else 0.0
	_player_panel_fixed_height = _player_panel.size.y if _player_panel != null else 0.0

	_cache_panel_styleboxes()
	_rebuild_panel_views()
	_configure_dialogue_labels()
	_initialize_runtime_defaults()

	configure(default_speaker_name, default_dialogue_text)

	if show_on_ready:
		_show_active_panel_for_speaker(default_speaker_name)
	else:
		_hide_all_panels()

	hide()


func configure(speaker_name: String, dialogue_text: String) -> void:
	_show_active_panel_for_speaker(speaker_name)
	set_speaker_name(speaker_name)
	set_dialogue_text(dialogue_text)
	refresh_layout()


func show_dialogue(speaker_name: String = "", dialogue_text: String = "") -> void:
	var previous_panel_key := _active_panel_key
	var target_panel_key := PLAYER_PANEL_KEY if _is_player_speaker(speaker_name) else NPC_PANEL_KEY
	if _panel_switch_pending:
		_pending_switch_panel_key = target_panel_key
		_pending_switch_speaker_name = speaker_name
		_pending_switch_dialogue_text = dialogue_text
		return

	if _should_queue_panel_switch(previous_panel_key, target_panel_key):
		_queue_panel_switch(target_panel_key, speaker_name, dialogue_text)
		return

	var should_play_enter := previous_panel_key != target_panel_key
	if not should_play_enter:
		var target_panel := _player_panel if target_panel_key == PLAYER_PANEL_KEY else _npc_panel
		should_play_enter = target_panel != null and not target_panel.visible

	if should_play_enter:
		_prepare_panel_for_enter_animation(target_panel_key)

	_show_active_panel_for_speaker(speaker_name)

	if speaker_name != "":
		set_speaker_name(speaker_name)

	if dialogue_text != "":
		set_dialogue_text(dialogue_text)

	if _active_panel != null:
		_active_panel.show()

	refresh_layout()

	if should_play_enter:
		_play_panel_animation(target_panel_key, _get_enter_animation_name(target_panel_key))


func show_configured_dialogue(extra_game_states: Array = []) -> Node:
	var resource: DialogueResource = _get_configured_dialogue_resource()
	if resource == null:
		push_warning("BoxDialogues: no hay diálogo asignado en dialogue_resource ni en dialogue_path")
		return null

	var dialogue_manager: Variant = Engine.get_singleton("DialogueManager")
	if dialogue_manager == null:
		push_warning("BoxDialogues: DialogueManager no está disponible")
		return null

	var title_to_use: String = _resolve_dialogue_title(resource)
	return dialogue_manager.show_dialogue_balloon_scene(dialogue_balloon_scene_path, resource, title_to_use, extra_game_states)


func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	_temporary_game_states = [self] + extra_game_states
	_is_waiting_for_input = false
	set_anchor_targets(_resolve_npc_anchor_target(extra_game_states), _resolve_player_anchor_target())

	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource

	if not title.is_empty():
		dialogue_title = title

	_runtime_dialogue_resource = _get_configured_dialogue_resource()
	var runtime_resource := _get_runtime_dialogue_resource()
	if runtime_resource == null:
		push_warning("BoxDialogues: no hay diálogo asignado en dialogue_resource ni en dialogue_path")
		if owner == null:
			queue_free()
		else:
			hide_dialogue(true)
		return

	show()
	_current_line = await runtime_resource.get_next_dialogue_line(_resolve_dialogue_title(runtime_resource), _temporary_game_states)
	_apply_current_line()
	_update_panel_position()


func next(next_id: String) -> void:
	var runtime_resource := _get_runtime_dialogue_resource()
	if runtime_resource == null:
		return

	_is_waiting_for_input = false
	_current_line = await runtime_resource.get_next_dialogue_line(next_id, _temporary_game_states)
	_apply_current_line()


func hide_dialogue(clear_content: bool = false) -> void:
	var exit_animation := _get_exit_animation_name(_active_panel_key)
	if _should_play_exit_animation(_active_panel_key, exit_animation):
		_hide_clear_content_requested = clear_content or clear_text_on_hide
		_hide_animation_pending = true
		_pending_hide_animation = exit_animation
		_play_panel_animation(_active_panel_key, exit_animation)
		return

	_finalize_hide_dialogue(clear_content)


func _finalize_hide_dialogue(clear_content: bool = false) -> void:
	_hide_all_panels()
	hide()
	_current_line = null
	_runtime_dialogue_resource = null
	_hide_animation_pending = false
	_pending_hide_animation = &""
	_hide_clear_content_requested = false
	var should_queue_free := _queue_free_after_hide
	_queue_free_after_hide = false
	set_anchor_targets(null, null)
	_reset_all_panel_visual_states()

	if clear_content or clear_text_on_hide:
		clear_dialogue()

	if should_queue_free:
		queue_free()


func set_anchor_targets(npc_target: Node2D = null, player_target: Node2D = null) -> void:
	_npc_anchor_target = npc_target
	_player_anchor_target = player_target


func refresh_layout() -> void:
	_refresh_active_panel_size()
	_update_panel_position()


func set_speaker_name(speaker_name: String) -> void:
	if _active_speaker_label == null:
		return

	var cleaned_name := speaker_name.strip_edges()
	_active_speaker_label.text = cleaned_name
	_active_speaker_label.visible = cleaned_name != ""


func set_dialogue_text(dialogue_text: String) -> void:
	if _active_dialogue_label == null:
		return

	_active_dialogue_label.text = dialogue_text.strip_edges()


func clear_dialogue() -> void:
	_clear_response_buttons()
	set_speaker_name("")
	set_dialogue_text("")


func is_dialogue_visible() -> bool:
	return _active_panel != null and _active_panel.visible


func get_speaker_name() -> String:
	if _active_speaker_label == null:
		return ""

	return _active_speaker_label.text


func get_dialogue_text() -> String:
	if _active_dialogue_label == null:
		return ""

	return _active_dialogue_label.text


func _get_configured_dialogue_resource() -> DialogueResource:
	if dialogue_resource != null:
		return dialogue_resource

	if dialogue_path.strip_edges() == "":
		return null

	return load(dialogue_path) as DialogueResource


func _get_runtime_dialogue_resource() -> DialogueResource:
	if _runtime_dialogue_resource != null:
		return _runtime_dialogue_resource

	return _get_configured_dialogue_resource()


func _resolve_dialogue_title(resource: DialogueResource) -> String:
	if dialogue_title.strip_edges() != "":
		return dialogue_title.strip_edges()

	if resource != null and resource.first_title.strip_edges() != "":
		return resource.first_title.strip_edges()

	return "start"


func _apply_current_line() -> void:
	_clear_response_buttons()

	if _current_line == null:
		_queue_free_after_hide = owner == null
		hide_dialogue(true)
		return

	show_dialogue(_current_line.character, _current_line.text)
	refresh_layout()

	if _current_line.responses.size() > 0:
		_create_response_buttons(_current_line.responses)
		refresh_layout()
		_is_waiting_for_input = false
		return

	if _current_line.time != "":
		var delay := _current_line.text.length() * 0.02 if _current_line.time == "auto" else _current_line.time.to_float()
		await get_tree().create_timer(delay).timeout
		next(_current_line.next_id)
		return

	_is_waiting_for_input = true


func _create_response_buttons(responses: Array) -> void:
	if _active_response_container == null:
		return

	for response in responses:
		var button := Button.new()
		button.text = response.text
		button.disabled = not response.is_allowed
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_response_selected.bind(response))
		_active_response_container.add_child(button)
		_response_buttons.append(button)

	if _response_buttons.size() > 0:
		_response_buttons[0].grab_focus()


func _clear_response_buttons() -> void:
	for button in _response_buttons:
		if is_instance_valid(button):
			button.queue_free()
	_response_buttons.clear()


func _unhandled_input(event: InputEvent) -> void:
	if _active_panel == null or not _active_panel.visible:
		return

	get_viewport().set_input_as_handled()

	if not _is_waiting_for_input or _is_input_temporarily_locked():
		return

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(_current_line.next_id)
	elif event.is_action_pressed(next_action):
		next(_current_line.next_id)


func _on_response_selected(response: DialogueResponse) -> void:
	if _is_input_temporarily_locked():
		return

	next(response.next_id)


func _process(_delta: float) -> void:
	if track_target_in_screen and _active_panel != null and _active_panel.visible and is_instance_valid(_get_active_anchor_target()):
		_update_panel_position()


func _resolve_npc_anchor_target(extra_game_states: Array) -> Node2D:
	for state in extra_game_states:
		if state is Node2D:
			return state as Node2D

	return null


func _resolve_player_anchor_target() -> Node2D:
	var player_node := get_tree().get_first_node_in_group(String(player_group_name))
	if player_node is Node2D:
		return player_node as Node2D

	return null


func _update_panel_position() -> void:
	if _active_panel == null or not is_instance_valid(_active_panel):
		return

	var anchor_target: Node2D = _get_active_anchor_target()
	if not is_instance_valid(anchor_target):
		return

	var canvas_transform := get_viewport().get_canvas_transform()
	var screen_position: Vector2 = canvas_transform * anchor_target.global_position
	var target_position: Vector2 = _resolve_dynamic_panel_position(screen_position)

	if clamp_to_viewport:
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		target_position.x = clamp(target_position.x, 0.0, max(0.0, viewport_size.x - _active_panel.size.x))
		target_position.y = clamp(target_position.y, 0.0, max(0.0, viewport_size.y - _active_panel.size.y))

	_apply_active_panel_stylebox()
	_active_panel.position = target_position


func _get_active_anchor_target() -> Node2D:
	return _player_anchor_target if _active_panel_key == PLAYER_PANEL_KEY else _npc_anchor_target


func _get_other_anchor_target() -> Node2D:
	return _npc_anchor_target if _active_panel_key == PLAYER_PANEL_KEY else _player_anchor_target


func _resolve_dynamic_panel_position(screen_position: Vector2) -> Vector2:
	var active_view: Dictionary = _get_active_panel_view()
	var side_offset: Vector2 = active_view.get("side_offset", Vector2.ZERO)
	var prefer_right: bool = _active_panel_key == PLAYER_PANEL_KEY
	var preferred_position: Vector2 = _build_side_position(screen_position, side_offset, prefer_right)
	var fallback_position: Vector2 = _build_side_position(screen_position, side_offset, not prefer_right)

	var preferred_score: int = _score_panel_position(preferred_position)
	var fallback_score: int = _score_panel_position(fallback_position)

	if fallback_score > preferred_score:
		_active_panel_on_right = not prefer_right
		return fallback_position

	_active_panel_on_right = prefer_right
	return preferred_position


func _build_side_position(screen_position: Vector2, side_offset: Vector2, to_right: bool) -> Vector2:
	return Vector2(
		screen_position.x + side_offset.x if to_right else screen_position.x - _active_panel.size.x - side_offset.x,
		screen_position.y - (_active_panel.size.y * 0.5) + side_offset.y
	)


func _score_panel_position(target_position: Vector2) -> int:
	var score := 0
	var panel_rect := Rect2(target_position, _active_panel.size)
	var viewport_rect := get_viewport().get_visible_rect()

	if viewport_rect.encloses(panel_rect):
		score += 2

	var other_anchor: Node2D = _get_other_anchor_target()
	if is_instance_valid(other_anchor):
		var other_screen_position: Vector2 = get_viewport().get_canvas_transform() * other_anchor.global_position
		if not _rect_contains_anchor(panel_rect, other_screen_position):
			score += 4
		else:
			score -= 4

	var active_anchor: Node2D = _get_active_anchor_target()
	if is_instance_valid(active_anchor):
		var active_screen_position: Vector2 = get_viewport().get_canvas_transform() * active_anchor.global_position
		if _rect_contains_anchor(panel_rect, active_screen_position):
			score -= 2

	return score


func _rect_contains_anchor(rect: Rect2, anchor_position: Vector2) -> bool:
	var expanded_rect := rect.grow(anchor_clearance_radius)
	return expanded_rect.has_point(anchor_position)


func _show_active_panel_for_speaker(speaker_name: String) -> void:
	var panel_key := PLAYER_PANEL_KEY if _is_player_speaker(speaker_name) else NPC_PANEL_KEY
	_set_active_panel_key(panel_key)


func _hide_all_panels() -> void:
	if _npc_panel != null:
		_npc_panel.hide()
	if _player_panel != null:
		_player_panel.hide()


func _initialize_runtime_defaults() -> void:
	if player_group_name == &"":
		player_group_name = StringName(String(GameConstants.group_player()))

	if dialogue_balloon_scene_path.strip_edges() == "":
		dialogue_balloon_scene_path = scene_file_path


func _should_play_exit_animation(panel_key: StringName, animation_name: StringName) -> bool:
	if _hide_animation_pending:
		return false

	var panel: Control = _get_panel_view(panel_key).get("panel", null) as Control
	if panel == null or not panel.visible:
		return false

	return _has_animation(animation_name)


func _should_queue_panel_switch(current_panel_key: StringName, target_panel_key: StringName) -> bool:
	if current_panel_key == target_panel_key:
		return false

	var exit_animation := _get_exit_animation_name(current_panel_key)
	return _should_play_exit_animation(current_panel_key, exit_animation)


func _queue_panel_switch(target_panel_key: StringName, speaker_name: String, dialogue_text: String) -> void:
	_panel_switch_pending = true
	_pending_switch_panel_key = target_panel_key
	_pending_switch_speaker_name = speaker_name
	_pending_switch_dialogue_text = dialogue_text
	_pending_switch_exit_animation = _get_exit_animation_name(_active_panel_key)
	_play_panel_animation(_active_panel_key, _pending_switch_exit_animation)


func _play_panel_animation(panel_key: StringName, animation_name: StringName) -> void:
	if not _has_animation(animation_name):
		_reset_panel_visual_state(panel_key)
		return

	var panel: Control = _get_panel_view(panel_key).get("panel", null) as Control
	if panel != null:
		panel.show()

	_lock_input_for_animation(animation_name)
	_animation_player.play(String(animation_name))


func _prepare_panel_for_enter_animation(panel_key: StringName) -> void:
	var animation_name := _get_enter_animation_name(panel_key)
	if not _has_animation(animation_name):
		_reset_panel_visual_state(panel_key)
		return

	var panel: Control = _get_panel_view(panel_key).get("panel", null) as Control
	if panel == null:
		return

	var transparent_modulate := panel.modulate
	transparent_modulate.a = 0.0
	panel.modulate = transparent_modulate


func _reset_all_panel_visual_states() -> void:
	_reset_panel_visual_state(NPC_PANEL_KEY)
	_reset_panel_visual_state(PLAYER_PANEL_KEY)


func _reset_panel_visual_state(panel_key: StringName) -> void:
	var panel: Control = _get_panel_view(panel_key).get("panel", null) as Control
	if panel == null:
		return

	var visible_modulate := panel.modulate
	visible_modulate.a = 1.0
	panel.modulate = visible_modulate


func _get_enter_animation_name(panel_key: StringName) -> StringName:
	return player_enter_animation if panel_key == PLAYER_PANEL_KEY else npc_enter_animation


func _get_exit_animation_name(panel_key: StringName) -> StringName:
	return player_exit_animation if panel_key == PLAYER_PANEL_KEY else npc_exit_animation


func _has_animation(animation_name: StringName) -> bool:
	return _animation_player != null and not String(animation_name).is_empty() and _animation_player.has_animation(String(animation_name))


func _lock_input_for_animation(animation_name: StringName) -> void:
	var lock_duration := animation_safety_time
	if _animation_player != null and _animation_player.has_animation(String(animation_name)):
		lock_duration = maxf(lock_duration, _animation_player.get_animation(String(animation_name)).length)

	_input_locked_until_msec = Time.get_ticks_msec() + int(ceil(lock_duration * 1000.0))


func _is_input_temporarily_locked() -> bool:
	return Time.get_ticks_msec() < _input_locked_until_msec


func _on_animation_player_animation_finished(animation_name: StringName) -> void:
	if not _hide_animation_pending:
		if _panel_switch_pending and animation_name == _pending_switch_exit_animation:
			_complete_pending_panel_switch()
		return

	if animation_name != _pending_hide_animation:
		return

	_finalize_hide_dialogue(_hide_clear_content_requested)


func _complete_pending_panel_switch() -> void:
	var next_panel_key := _pending_switch_panel_key
	var next_speaker_name := _pending_switch_speaker_name
	var next_dialogue_text := _pending_switch_dialogue_text
	_panel_switch_pending = false
	_pending_switch_exit_animation = &""
	_pending_switch_speaker_name = ""
	_pending_switch_dialogue_text = ""
	_hide_all_panels()
	_prepare_panel_for_enter_animation(next_panel_key)
	_show_active_panel_for_speaker(next_speaker_name)

	if next_speaker_name != "":
		set_speaker_name(next_speaker_name)

	if next_dialogue_text != "":
		set_dialogue_text(next_dialogue_text)

	if _active_panel != null:
		_active_panel.show()

	refresh_layout()
	_play_panel_animation(next_panel_key, _get_enter_animation_name(next_panel_key))


func _is_player_speaker(speaker_name: String) -> bool:
	var cleaned_name := speaker_name.strip_edges().to_lower()
	if cleaned_name == "":
		return false

	for player_name in player_speaker_names:
		if cleaned_name == player_name.strip_edges().to_lower():
			return true

	return false


func _cache_panel_styleboxes() -> void:
	_npc_left_stylebox = _duplicate_panel_stylebox(_npc_panel)
	_npc_right_stylebox = _build_mirrored_stylebox(_npc_left_stylebox)
	_player_left_stylebox = _duplicate_panel_stylebox(_player_panel)
	_player_right_stylebox = _build_mirrored_stylebox(_player_left_stylebox)


func _rebuild_panel_views() -> void:
	_panel_views.clear()
	_panel_views[NPC_PANEL_KEY] = _create_panel_view(
		_npc_panel,
		_npc_response_container,
		_npc_speaker_label,
		_npc_dialogue_label,
		npc_side_offset,
		_npc_panel_fixed_height,
		_npc_left_stylebox,
		_npc_right_stylebox
	)
	_panel_views[PLAYER_PANEL_KEY] = _create_panel_view(
		_player_panel,
		_player_response_container,
		_player_speaker_label,
		_player_dialogue_label,
		player_side_offset,
		_player_panel_fixed_height,
		_player_left_stylebox,
		_player_right_stylebox
	)
	_set_active_panel_key(_active_panel_key)


func _create_panel_view(panel: Control, response_container: Control, speaker_label: Label, dialogue_label: Label, side_offset: Vector2, fixed_height: float, left_stylebox: StyleBox, right_stylebox: StyleBox) -> Dictionary:
	return {
		"panel": panel,
		"response_container": response_container,
		"speaker_label": speaker_label,
		"dialogue_label": dialogue_label,
		"side_offset": side_offset,
		"fixed_height": fixed_height,
		"left_stylebox": left_stylebox,
		"right_stylebox": right_stylebox,
	}


func _set_active_panel_key(panel_key: StringName) -> void:
	var resolved_key: StringName = panel_key
	if resolved_key == PLAYER_PANEL_KEY and _player_panel == null:
		resolved_key = NPC_PANEL_KEY

	_active_panel_key = resolved_key
	var active_view: Dictionary = _get_active_panel_view()
	_active_panel = active_view.get("panel", null) as Control
	_active_response_container = active_view.get("response_container", null) as Control
	_active_speaker_label = active_view.get("speaker_label", null) as Label
	_active_dialogue_label = active_view.get("dialogue_label", null) as Label

	if _npc_panel != null:
		_npc_panel.visible = _active_panel == _npc_panel
	if _player_panel != null:
		_player_panel.visible = _active_panel == _player_panel

	_apply_active_panel_stylebox()


func _get_panel_view(panel_key: StringName) -> Dictionary:
	if not _panel_views.has(panel_key):
		return {}

	return _panel_views[panel_key]


func _get_active_panel_view() -> Dictionary:
	return _get_panel_view(_active_panel_key)


func _configure_dialogue_labels() -> void:
	for panel_view in _panel_views.values():
		_setup_dialogue_label(panel_view.get("dialogue_label", null) as Label)


func _setup_dialogue_label(label: Label) -> void:
	if label == null:
		return

	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true


func _refresh_active_panel_size() -> void:
	if _active_panel == null or _active_dialogue_label == null:
		return

	var target_width := _calculate_target_panel_width()
	var fixed_height := _get_active_panel_fixed_height()
	_active_dialogue_label.custom_minimum_size.x = target_width

	if _active_speaker_label != null:
		_active_speaker_label.custom_minimum_size.x = target_width

	if _active_response_container != null:
		_active_response_container.custom_minimum_size.x = target_width

	_active_panel.custom_minimum_size = Vector2(0.0, fixed_height)
	_active_panel.reset_size()
	_active_panel.size = Vector2(_active_panel.get_combined_minimum_size().x, fixed_height)


func _get_active_panel_fixed_height() -> float:
	var active_view: Dictionary = _get_active_panel_view()
	if active_view.is_empty():
		return 0.0

	return active_view.get("fixed_height", 0.0)


func _calculate_target_panel_width() -> float:
	var target_width := maxf(dialogue_panel_min_width, _measure_label_text_width(_active_speaker_label))
	target_width = maxf(target_width, _measure_label_text_width(_active_dialogue_label))
	if dialogue_panel_max_width > 0.0:
		target_width = minf(target_width, dialogue_panel_max_width)

	return target_width


func _measure_label_text_width(label: Label) -> float:
	if label == null:
		return 0.0

	var content := label.text.strip_edges()
	if content.is_empty():
		return 0.0

	var font := label.get_theme_font("font")
	if font == null:
		return label.get_minimum_size().x

	var font_size := label.get_theme_font_size("font_size")
	var widest_line := 0.0
	for line in content.split("\n"):
		widest_line = maxf(widest_line, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)

	return widest_line + 8.0


func _duplicate_panel_stylebox(panel: Control) -> StyleBox:
	if panel == null:
		return null

	var stylebox := panel.get_theme_stylebox("panel")
	if stylebox == null:
		return null

	return stylebox.duplicate(true)


func _build_mirrored_stylebox(base_stylebox: StyleBox) -> StyleBox:
	if base_stylebox == null:
		return null

	var mirrored_stylebox: StyleBox = base_stylebox.duplicate(true) as StyleBox
	if mirrored_stylebox is StyleBoxTexture:
		var mirrored_texture_stylebox: StyleBoxTexture = mirrored_stylebox as StyleBoxTexture
		if mirrored_texture_stylebox.texture != null:
			var image: Image = mirrored_texture_stylebox.texture.get_image()
			if image != null:
				image.flip_x()
				mirrored_texture_stylebox.texture = ImageTexture.create_from_image(image)

			var left_margin: float = mirrored_texture_stylebox.texture_margin_left
			mirrored_texture_stylebox.texture_margin_left = mirrored_texture_stylebox.texture_margin_right
			mirrored_texture_stylebox.texture_margin_right = left_margin

	return mirrored_stylebox


func _apply_active_panel_stylebox() -> void:
	if _active_panel == null:
		return

	var active_view: Dictionary = _get_active_panel_view()
	var stylebox: StyleBox = active_view.get("right_stylebox", null) as StyleBox if _active_panel_on_right else active_view.get("left_stylebox", null) as StyleBox

	if stylebox != null:
		_active_panel.add_theme_stylebox_override("panel", stylebox)