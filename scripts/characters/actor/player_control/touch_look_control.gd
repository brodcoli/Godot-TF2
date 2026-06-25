extends Control

@onready var player_control: ActorPlayerControl = $"../../../../PlayerControl"
@onready var move_control: Control = $MoveControl

var is_dragging = false
var has_dragged = false
var initial_press_position = Vector2()
var last_drag_position = Vector2()
var touch_sensitivity_multiplier: float = 0.32
var drag_touch_index: int = -1
const DRAG_THRESHOLD = 10.0



func _ready():

	check_aspect_ratio()

	get_tree().root.connect("size_changed", check_aspect_ratio)

func check_aspect_ratio():
	var window_size = DisplayServer.window_get_size()
	var aspect_ratio = float(window_size.x) / float(window_size.y)



func _input(event):
	if not _can_handle_touch_input():
		is_dragging = false
		drag_touch_index = -1
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if drag_touch_index == -1 and not move_control.is_within_touch_control(event.position):
				is_dragging = true
				has_dragged = false
				initial_press_position = event.position
				last_drag_position = event.position
				drag_touch_index = event.index
		else:
			if event.index == drag_touch_index:
				is_dragging = false
				drag_touch_index = -1
				if not has_dragged or event.position.distance_to(initial_press_position) < DRAG_THRESHOLD:
					_trigger_use_action()
	elif event is InputEventScreenDrag and is_dragging and event.index == drag_touch_index:
		if event.position.distance_to(initial_press_position) >= DRAG_THRESHOLD:
			has_dragged = true
			_handle_drag(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not move_control.is_within_touch_control(event.position):
					is_dragging = true
					has_dragged = false
					initial_press_position = event.position
					last_drag_position = event.position
			else:
				if is_dragging:
					is_dragging = false
					if not has_dragged or event.position.distance_to(initial_press_position) < DRAG_THRESHOLD:
						_trigger_use_action()
	elif event is InputEventMouseMotion and is_dragging:
		if event.position.distance_to(initial_press_position) >= DRAG_THRESHOLD:
			has_dragged = true
			_handle_drag(event.relative)

func _trigger_use_action():
	Input.action_press("use")
	await get_tree().process_frame
	Input.action_release("use")

func _can_handle_touch_input() -> bool:
	return (
		Settings.use_touch_controls
		and visible
		and is_visible_in_tree()
		and player_control != null
		and player_control.is_player_controlled
		and not PauseManager.paused
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	)




func _handle_drag(drag_amount: Vector2):
	player_control.touch_control_look_dir += drag_amount * touch_sensitivity_multiplier


func _on_pause_btn_pressed() -> void:
	PauseManager.paused = not PauseManager.paused
