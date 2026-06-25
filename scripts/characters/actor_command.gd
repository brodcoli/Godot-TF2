extends RefCounted
class_name ActorCommand

var move_dir: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var jump_held: bool = false
var use_pressed: bool = false
var use_held: bool = false
var exit_vehicle_pressed: bool = false
var inputs_disabled: bool = false
var movement_disabled: bool = false

var _jump_pressed_once := false
var _use_pressed_once := false
var _exit_vehicle_pressed_once := false

func press_jump_once() -> void:
	jump_pressed = true
	_jump_pressed_once = true

func press_use_once() -> void:
	use_pressed = true
	_use_pressed_once = true

func press_exit_vehicle_once() -> void:
	exit_vehicle_pressed = true
	_exit_vehicle_pressed_once = true

func is_jump_just_pressed() -> bool:
	var pressed := jump_pressed
	if _jump_pressed_once:
		jump_pressed = false
		_jump_pressed_once = false
	return pressed

func is_use_just_pressed() -> bool:
	var pressed := use_pressed
	if _use_pressed_once:
		use_pressed = false
		_use_pressed_once = false
	return pressed

func is_exit_vehicle_just_pressed() -> bool:
	var pressed := exit_vehicle_pressed
	if _exit_vehicle_pressed_once:
		exit_vehicle_pressed = false
		_exit_vehicle_pressed_once = false
	return pressed

func clear_transient() -> void:
	look_delta = Vector2.ZERO
	jump_pressed = false
	use_pressed = false
	exit_vehicle_pressed = false
	_jump_pressed_once = false
	_use_pressed_once = false
	_exit_vehicle_pressed_once = false

func clear_input_values(clear_look := true) -> void:
	move_dir = Vector2.ZERO
	if clear_look:
		look_delta = Vector2.ZERO
	jump_pressed = false
	jump_held = false
	use_pressed = false
	use_held = false
	exit_vehicle_pressed = false
	_jump_pressed_once = false
	_use_pressed_once = false
	_exit_vehicle_pressed_once = false
