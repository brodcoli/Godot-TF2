extends Node3D
class_name MapKOTH

const CAPTURE_UNLOCK_DELAY := 6.0
const COUNTDOWN_SECONDS := 5

@export var control_point: ControlPoint

@onready var _main_cp: ControlPointUI = $MapUI/Control/ControlPointUI

func _ready() -> void:
	control_point.is_capturable = false
	_main_cp.is_capturable = control_point.is_capturable
	control_point.captured.connect(_on_cp_captured)
	control_point.capture_progress_changed.connect(_on_cp_capture_progress_changed)
	_start_capture_unlock_countdown()

func _on_cp_captured(team):
	_main_cp.capture_color = team.color


func _on_cp_capture_progress_changed(progress: float, team: Team) -> void:
	_main_cp.capture_percentage = progress
	_main_cp.set_capture_progress_team(team)


func _start_capture_unlock_countdown() -> void:
	_main_cp.countdown_text = ""

	await get_tree().create_timer(CAPTURE_UNLOCK_DELAY - COUNTDOWN_SECONDS).timeout

	for seconds_left in range(COUNTDOWN_SECONDS, 0, -1):
		_main_cp.countdown_text = str(seconds_left)
		await get_tree().create_timer(1.0).timeout

	control_point.is_capturable = true
	_main_cp.is_capturable = control_point.is_capturable
	_main_cp.countdown_text = ""
