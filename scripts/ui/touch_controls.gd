extends Node

@onready var _player_control: ActorPlayerControl = $"../../PlayerControl"

var _prev_show_touch_controls = false
var _player_ui_visible = false

func _ready() -> void:
	for node in get_children():
		node.visible = false

func _process(delta: float) -> void:
	var show_touch_controls = _player_ui_visible and Settings.use_touch_controls and _player_control != null and _player_control.is_player_controlled

	if show_touch_controls != _prev_show_touch_controls:
		for node in get_children():
			node.visible = show_touch_controls

		_prev_show_touch_controls = show_touch_controls

func set_player_ui_visible(is_visible: bool) -> void:
	_player_ui_visible = is_visible
	_prev_show_touch_controls = not is_visible

	for node in get_children():
		node.visible = false

func _on_toggle_cam_pressed() -> void:
	if _player_control:
		_player_control.toggle_camera()
