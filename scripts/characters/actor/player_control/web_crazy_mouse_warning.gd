extends Control

const mouse_y_threshold = 130.0
const how_many_times_in_a_single_second = 25
const seconds_under_threshold_to_hide = 2.0

@onready var _player_control: ActorPlayerControl = $"../../../PlayerControl"

var _high_y_timestamps: Array[float] = []
var _time_moved_under_threshold: float = 0.0
var _mouse_moved_this_frame: bool = false

var _resized_for_small_window = false

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if _player_control == null or not _player_control.is_player_controlled:
		visible = false
		return

	if visible:
		if not _resized_for_small_window:
			var win_size = get_window().size
			if win_size.x < 1000:
				$RichTextLabel.size.x = win_size.x - 40
				$RichTextLabel.position.x = (win_size.x / 2.0) - ($RichTextLabel.size.x / 2.0)
				_resized_for_small_window = true

		if Settings.use_touch_controls:
			visible = false

		if _mouse_moved_this_frame:
			_time_moved_under_threshold += delta
			if _time_moved_under_threshold > seconds_under_threshold_to_hide:
				visible = false

	_mouse_moved_this_frame = false

func _input(event: InputEvent):
	if _player_control == null or not _player_control.is_player_controlled:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_moved_this_frame = true

		if abs(event.screen_relative.y) > mouse_y_threshold:
			_time_moved_under_threshold = 0.0
			var current_time = Time.get_ticks_msec() / 1000.0
			_high_y_timestamps.append(current_time)

			while _high_y_timestamps.size() > 0 and current_time - _high_y_timestamps[0] > 1.0:
				_high_y_timestamps.pop_front()

			if _high_y_timestamps.size() > how_many_times_in_a_single_second:
				print("Crazy mouse warning: y > " + str(mouse_y_threshold) + " more than " + str(how_many_times_in_a_single_second) + " times in 1 second!")
				_high_y_timestamps.clear()
				visible = true
