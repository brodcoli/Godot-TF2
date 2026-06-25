extends Control
class_name ControlPointUI

const LOCK_ICON := "🔒"

@onready var _countdown_label: Label = %CountdownLabel
@onready var _capture_progress_fill: ColorRect = %CaptureProgressFill

var capture_color: Color:
	set(value):
		capture_color = value
		$MarginContainer/Fill.color = capture_color

var capture_percentage := 0.0:
	set(value):
		capture_percentage = clampf(value, 0.0, 1.0)
		_update_capture_progress()

var capture_progress_color := Color(0.91, 0.191, 0.191):
	set(value):
		capture_progress_color = value
		_update_capture_progress()

var is_capturable := false:
	set(value):
		is_capturable = value
		_update_countdown_label()

var countdown_text := "":
	set(value):
		countdown_text = value
		_update_countdown_label()


func set_countdown_text(value: String) -> void:
	countdown_text = value


func set_capture_progress(value: float) -> void:
	capture_percentage = value


func set_capture_progress_team(team: Team) -> void:
	if team == null:
		return

	capture_progress_color = Color(team.color.r, team.color.g, team.color.b)


func _ready() -> void:
	_update_countdown_label()
	_update_capture_progress()


func _update_countdown_label() -> void:
	if not is_node_ready():
		return

	if not countdown_text.is_empty():
		_countdown_label.text = countdown_text
	elif not is_capturable:
		_countdown_label.text = LOCK_ICON
	else:
		_countdown_label.text = ""


func _update_capture_progress() -> void:
	if not is_node_ready():
		return

	_capture_progress_fill.anchor_left = 1.0 - capture_percentage
	_capture_progress_fill.anchor_right = 1.0
	_capture_progress_fill.offset_left = 0.0
	_capture_progress_fill.offset_top = 0.0
	_capture_progress_fill.offset_right = 0.0
	_capture_progress_fill.offset_bottom = 0.0
	_capture_progress_fill.color = Color(
		capture_progress_color.r,
		capture_progress_color.g,
		capture_progress_color.b,
		_capture_progress_fill.color.a
	)
