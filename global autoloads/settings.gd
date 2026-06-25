extends Node

func _ready() -> void:
	limit_fps = Engine.max_fps
	vsync = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	resolution_scale = get_window().content_scale_factor
	window_mode = DisplayServer.window_get_mode()


	var bus_index = AudioServer.get_bus_index("Master")
	var linear_vol = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	vol_master = sqrt(linear_vol) * 100.0

	bus_index = AudioServer.get_bus_index("Music")
	linear_vol = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	vol_music = sqrt(linear_vol) * 100.0

	bus_index = AudioServer.get_bus_index("SFX")
	linear_vol = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	vol_sfx = sqrt(linear_vol) * 100.0

	bus_index = AudioServer.get_bus_index("Wind")
	linear_vol = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	vol_wind = sqrt(linear_vol) * 100.0

	shadow_res = get_window().positional_shadow_atlas_size

	var env: Environment = load("res://environments/main_env.tres")
	if env:
		ssao = env.ssao_enabled

	if _is_mobile_web():
		auto_turn_vehicles = true
		use_touch_controls = true
		shadow_res = 2048

	get_window().size_changed.connect(_on_window_size_changed)
	_on_window_size_changed()

var camera_fov: int = 80

enum UIScale {
	TINY,
	SMALL,
	NORMAL,
	LARGE,
	HUGE
}

var ui_scale: UIScale = UIScale.NORMAL:
	set(value):
		ui_scale = value
		var scale_val = 1.0
		if ui_scale == UIScale.TINY:
			scale_val = 0.5
		elif ui_scale == UIScale.SMALL:
			scale_val = 0.75
		elif ui_scale == UIScale.NORMAL:
			scale_val = 1.0
		elif ui_scale == UIScale.LARGE:
			scale_val = 1.5
		elif ui_scale == UIScale.HUGE:
			scale_val = 2.0

		get_window().content_scale_factor = scale_val

var limit_fps: int = 0:
	set(value):
		limit_fps = value
		Engine.max_fps = limit_fps

var vsync: bool = true:
	set(value):
		vsync = value
		if vsync:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

var resolution_scale: float = 1.5:
	set(value):
		resolution_scale = value
		get_window().content_scale_factor = resolution_scale

var window_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED:
	set(value):
		if window_mode == value:
			return
		window_mode = value
		if DisplayServer.window_get_mode() != window_mode:
			DisplayServer.window_set_mode(window_mode)










var vol_master: float = 100.0:
	set(value):
		vol_master = clamp(value, 0.0, 100.0)
		var bus_index = AudioServer.get_bus_index("Master")


		var v = vol_master / 100.0
		var exp_volume = v * v

		AudioServer.set_bus_volume_db(bus_index, linear_to_db(exp_volume))


var vol_music: float = 100.0:
	set(value):
		vol_music = clamp(value, 0.0, 100.0)
		var bus_index = AudioServer.get_bus_index("Music")


		var v = vol_music / 100.0
		var exp_volume = v * v

		AudioServer.set_bus_volume_db(bus_index, linear_to_db(exp_volume))


var vol_sfx: float = 100.0:
	set(value):
		vol_sfx = clamp(value, 0.0, 100.0)
		var bus_index = AudioServer.get_bus_index("SFX")


		var v = vol_sfx / 100.0
		var exp_volume = v * v

		AudioServer.set_bus_volume_db(bus_index, linear_to_db(exp_volume))


var vol_wind: float = 100.0:
	set(value):
		vol_wind = clamp(value, 0.0, 100.0)
		var bus_index = AudioServer.get_bus_index("Wind")


		var v = vol_wind / 100.0
		var exp_volume = v * v

		AudioServer.set_bus_volume_db(bus_index, linear_to_db(exp_volume))


var shadow_res: int = 1024:
	set(value):
		shadow_res = value
		RenderingServer.directional_shadow_atlas_set_size(value, true)
		if is_inside_tree():
			get_window().positional_shadow_atlas_size = value

var ssao: bool = true:
	set(value):
		ssao = value
		var env: Environment = load("res://environments/main_env.tres")
		if env:
			env.ssao_enabled = value

var mouse_sensitivity: float = 50.0

var disable_paint_screen_filter: bool = false

var disable_surface_scatters: bool = false

var _original_use_events
var use_touch_controls: bool = false:
	get:
		return use_touch_controls
	set(value):
		use_touch_controls = value
		if use_touch_controls:
			_original_use_events = InputMap.action_get_events("use")
			InputMap.action_erase_events("use")
		else:
			for action in _original_use_events:
				InputMap.action_add_event("use", action)

var auto_turn_vehicles: bool = false

var enable_noclip_for_all_players: bool = false


var _prev_window_size = Vector2i.ZERO
func _on_window_size_changed():
	_sync_window_mode_from_display_server()

	var window_size = get_window().size
	if window_size == _prev_window_size:
		return

	if window_size.x < 500:
		ui_scale = UIScale.SMALL
	elif window_size.x <= 1920:
		ui_scale = UIScale.NORMAL

	if window_size.y > 1920:
		ui_scale = UIScale.HUGE

	_prev_window_size = window_size

func _sync_window_mode_from_display_server() -> void:
	var current_window_mode = DisplayServer.window_get_mode()
	if window_mode != current_window_mode:
		window_mode = current_window_mode

func _is_mobile_web() -> bool:
	var is_android_web = OS.has_feature("web_android")
	var is_ios_web = OS.has_feature("web_ios")

	return is_android_web or is_ios_web
