extends Node

@onready var _player_control: ActorPlayerControl = $"../PlayerControl"

func _input(event: InputEvent) -> void:
	if _player_control == null or not _player_control.is_player_controlled:
		return
	if Input.is_action_just_pressed("toggle_fullscreen"):
		_toggle_fullscreen()

func _toggle_fullscreen():
	var window_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode(0)
	if window_mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
		Settings.window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	else:
		Settings.window_mode = DisplayServer.WINDOW_MODE_WINDOWED
