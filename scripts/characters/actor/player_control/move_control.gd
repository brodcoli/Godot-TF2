extends Control

@onready var _player_control: ActorPlayerControl = $"../../../../../PlayerControl"

const ORIGINAL_MOVE_CONTROL_DIAMETER = 1024

var hitbox_extra_buffer = 25

var is_touching = false
var _touch_index: int = -1

var _offset_y = 0.0
var _touch_pos = Vector2.ZERO
var _center: Vector2

func _ready():
	var screen_height = DisplayServer.window_get_size().y
	var screen_width = DisplayServer.window_get_size().x
	var shortest_dim = min(screen_width, screen_height)
	var desired_size = shortest_dim / 2.8
	var scale_factor = desired_size / ORIGINAL_MOVE_CONTROL_DIAMETER
	scale = Vector2(scale_factor, scale_factor)

func is_within_touch_control(pos: Vector2) -> bool:





	return (pos - _center).length() <= ORIGINAL_MOVE_CONTROL_DIAMETER/2.0 * scale.x + hitbox_extra_buffer

func _input(event: InputEvent):
	if not _can_handle_touch_input():
		is_touching = false
		_touch_index = -1
		return

	if event is InputEventMouseButton and not (event is InputEventScreenTouch):
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_within_touch_control(event.position):
				is_touching = true
				_touch_pos = event.position
			elif not event.pressed:
				is_touching = false
	elif event is InputEventScreenTouch:
		if event.pressed and is_within_touch_control(event.position) and _touch_index == -1:
			is_touching = true
			_touch_pos = event.position
			_touch_index = event.index
		elif not event.pressed and event.index == _touch_index:
			is_touching = false
			_touch_index = -1

	elif event is InputEventScreenDrag and is_touching and event.index == _touch_index:
		_touch_pos = event.position
	elif event is InputEventMouseMotion and is_touching and not (event is InputEventScreenDrag):
		_touch_pos = event.position

func _process(delta: float) -> void:
	if _player_control == null:
		return

	if not _can_handle_touch_input():
		_player_control.touch_control_move_dir = Vector2.ZERO
		return

	_center = $TextureRect.global_position + Vector2.ONE*ORIGINAL_MOVE_CONTROL_DIAMETER*scale/2.0
	if is_touching:
		var vector_to_input = _touch_pos - _center

		if vector_to_input.length() > 0:
			var angle = vector_to_input.angle()
			var rounded_angle = round(angle / (PI/4)) * (PI/4)
			var rounded_dir = Vector2(cos(rounded_angle), sin(rounded_angle))
			_player_control.touch_control_move_dir = rounded_dir
		else:
			_player_control.touch_control_move_dir = Vector2.ZERO
	else:
		_player_control.touch_control_move_dir = Vector2.ZERO

func _can_handle_touch_input() -> bool:
	return (
		Settings.use_touch_controls
		and visible
		and is_visible_in_tree()
		and _player_control != null
		and _player_control.is_player_controlled
		and not PauseManager.paused
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	)
