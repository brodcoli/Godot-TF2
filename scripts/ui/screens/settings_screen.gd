extends Control


var fov_slider: Slider
var fov_label: Label
var res_btn: OptionButton
var fps_btn: OptionButton
var vsync_btn: OptionButton
var shadow_btn: OptionButton
var ssao_btn: OptionButton
var vol_master: Slider
var vol_master_label: Label
var vol_music: Slider
var vol_music_label: Label
var vol_sfx: Slider
var vol_sfx_label: Label
var vol_wind: Slider
var vol_wind_label: Label
var sens_slider: Slider
var sens_label: Label
var noclip_btn: BaseButton
var ui_scale: OptionButton
var paint_filter: OptionButton
var force_touch_controls: OptionButton
var auto_turn_vehicles: OptionButton
var paint_res: OptionButton
var surface_scatter: OptionButton
var window_mode_btn: OptionButton


var _saved_performance_settings: Dictionary = {}

var _is_mobile_web = false

func _ready() -> void:
	await get_tree().process_frame

	fov_slider = get_node_or_null("%FOV")
	if not fov_slider: fov_slider = find_child("FOV")
	fov_label = get_node_or_null("%FOVLabel")
	if not fov_label: fov_label = find_child("FOVLabel")
	res_btn = find_child("Resolution")
	fps_btn = find_child("LimitFPS")
	vsync_btn = find_child("VSync")
	shadow_btn = find_child("ShadowRes")
	ssao_btn = find_child("SSAO")
	vol_master = find_child("MasterVol")
	vol_master_label = get_node_or_null("%MasterVolLabel2")
	if not vol_master_label: vol_master_label = find_child("MasterVolLabel2")
	vol_music = find_child("MusicVol")
	vol_music_label = get_node_or_null("%MusicVolLabel2")
	if not vol_music_label: vol_music_label = find_child("MusicVolLabel2")
	vol_sfx = find_child("SFXVol")
	vol_sfx_label = get_node_or_null("%SFXVolLabel2")
	if not vol_sfx_label: vol_sfx_label = find_child("SFXVolLabel2")
	vol_wind = find_child("WindVol")
	vol_wind_label = get_node_or_null("%WindVolLabel2")
	if not vol_wind_label: vol_wind_label = find_child("WindVolLabel2")
	sens_slider = find_child("Sens")
	sens_label = get_node_or_null("%SensLabel2")
	if not sens_label: sens_label = find_child("SensLabel2")
	noclip_btn = find_child("Noclip")
	ui_scale = find_child("UIScale")
	paint_filter = find_child("PaintFilter")
	force_touch_controls = find_child("ForceTouchControls")
	auto_turn_vehicles = find_child("AutoTurnVehicles")
	paint_res = find_child("PaintRes")
	surface_scatter = find_child("SurfaceScatter")
	window_mode_btn = find_child("WindowMode")


	var is_android_web = OS.has_feature("web_android")
	var is_ios_web = OS.has_feature("web_ios")
	_is_mobile_web = is_android_web or is_ios_web

	if _is_mobile_web:
		_prioritize_performance(true)


func _update_ui_from_settings() -> void:
	if fov_slider and fov_slider.value != Settings.camera_fov:
		fov_slider.set_value_no_signal(Settings.camera_fov)
	if fov_label:
		fov_label.text = str(Settings.camera_fov)

	if res_btn:
		var res_idx = 0
		if Settings.resolution_scale == 1.0: res_idx = 0
		elif Settings.resolution_scale == 1.05: res_idx = 1
		elif Settings.resolution_scale == 1.5: res_idx = 2
		elif Settings.resolution_scale == 2.0: res_idx = 3
		elif Settings.resolution_scale == 3.0: res_idx = 4
		if res_btn.selected != res_idx:
			res_btn.selected = res_idx

	if fps_btn:
		var fps_idx = 0
		if Settings.limit_fps == 0: fps_idx = 0
		elif Settings.limit_fps == 60: fps_idx = 1
		elif Settings.limit_fps == 45: fps_idx = 2
		elif Settings.limit_fps == 30: fps_idx = 3
		elif Settings.limit_fps == 24: fps_idx = 4
		if fps_btn.selected != fps_idx:
			fps_btn.selected = fps_idx

	if vsync_btn:
		var vs_idx = 0 if Settings.vsync else 1
		if vsync_btn.selected != vs_idx:
			vsync_btn.selected = vs_idx

	if shadow_btn:
		var sh_idx = 0
		if Settings.shadow_res == 1024: sh_idx = 0
		elif Settings.shadow_res == 2048: sh_idx = 1
		elif Settings.shadow_res == 4096: sh_idx = 2
		if shadow_btn.selected != sh_idx:
			shadow_btn.selected = sh_idx

	if ssao_btn:
		var ssao_idx = 0 if Settings.ssao else 1
		if ssao_btn.selected != ssao_idx:
			ssao_btn.selected = ssao_idx

	if vol_master and vol_master.value != Settings.vol_master:
		vol_master.set_value_no_signal(Settings.vol_master)
	if vol_master_label:
		vol_master_label.text = str(int(Settings.vol_master)) + "%"

	if vol_music and vol_music.value != Settings.vol_music:
		vol_music.set_value_no_signal(Settings.vol_music)
	if vol_music_label:
		vol_music_label.text = str(int(Settings.vol_music)) + "%"

	if vol_sfx and vol_sfx.value != Settings.vol_sfx:
		vol_sfx.set_value_no_signal(Settings.vol_sfx)
	if vol_sfx_label:
		vol_sfx_label.text = str(int(Settings.vol_sfx)) + "%"

	if vol_wind and vol_wind.value != Settings.vol_wind:
		vol_wind.set_value_no_signal(Settings.vol_wind)
	if vol_wind_label:
		vol_wind_label.text = str(int(Settings.vol_wind)) + "%"

	if sens_slider and sens_slider.value != Settings.mouse_sensitivity:
		sens_slider.set_value_no_signal(Settings.mouse_sensitivity)
	if sens_label:
		sens_label.text = str(int(Settings.mouse_sensitivity))

	if noclip_btn and noclip_btn.button_pressed != Settings.enable_noclip_for_all_players:
		noclip_btn.button_pressed = Settings.enable_noclip_for_all_players

	if ui_scale:
		var ui_idx = 2
		if Settings.ui_scale == Settings.UIScale.TINY: ui_idx = 0
		elif Settings.ui_scale == Settings.UIScale.SMALL: ui_idx = 1
		elif Settings.ui_scale == Settings.UIScale.NORMAL: ui_idx = 2
		elif Settings.ui_scale == Settings.UIScale.LARGE: ui_idx = 3
		elif Settings.ui_scale == Settings.UIScale.HUGE: ui_idx = 4
		if ui_scale.selected != ui_idx:
			ui_scale.selected = ui_idx

	if paint_filter:
		var pf_idx = 1 if Settings.disable_paint_screen_filter else 0
		if paint_filter.selected != pf_idx:
			paint_filter.selected = pf_idx

	if force_touch_controls:
		var tc_idx = 1 if Settings.use_touch_controls else 0
		if force_touch_controls.selected != tc_idx:
			force_touch_controls.selected = tc_idx

	if auto_turn_vehicles:
		var at_idx = 1 if Settings.auto_turn_vehicles else 0
		if auto_turn_vehicles.selected != at_idx:
			auto_turn_vehicles.selected = at_idx








	if surface_scatter:
		var ss_idx = 1 if Settings.disable_surface_scatters else 0
		if surface_scatter.selected != ss_idx:
			surface_scatter.selected = ss_idx

	if window_mode_btn:
		var mode_idx = 0
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN: mode_idx = 1
		if window_mode_btn.selected != mode_idx:
			window_mode_btn.selected = mode_idx










func _process(delta: float) -> void:
	if visible:
		_update_ui_from_settings()


		%FPSMonitorLabel.text = "FPS: " + str(int(Engine.get_frames_per_second()))

		var win_size = get_window().size






		if win_size.y < 600:
			$MainMargin.set("theme_override_constants/margin_top", 0)
			$MainMargin.set("theme_override_constants/margin_bottom", 0)
			%FPSMonitorLabel.visible = false
			%TitleMarginContainer.set("theme_override_constants/margin_top", 15)
			%TitleMarginContainer.set("theme_override_constants/margin_bottom", 5)
		elif win_size.y <= 860:
			$MainMargin.set("theme_override_constants/margin_top", 10)
			$MainMargin.set("theme_override_constants/margin_bottom", 10)
			%FPSMonitorLabel.visible = true
			%TitleMarginContainer.set("theme_override_constants/margin_top", 15)
			%TitleMarginContainer.set("theme_override_constants/margin_bottom", 15)
		else:
			$MainMargin.set("theme_override_constants/margin_top", 100)
			$MainMargin.set("theme_override_constants/margin_bottom", 100)
			%FPSMonitorLabel.visible = true
			%TitleMarginContainer.set("theme_override_constants/margin_top", 15)
			%TitleMarginContainer.set("theme_override_constants/margin_bottom", 15)

		if win_size.x < 500:
			$MainMargin.set("theme_override_constants/margin_left", 0)
			$MainMargin.set("theme_override_constants/margin_right", 0)
		elif win_size.x < 700:
			$MainMargin.set("theme_override_constants/margin_left", 10)
			$MainMargin.set("theme_override_constants/margin_right", 10)
		elif win_size.x < 900:
			$MainMargin.set("theme_override_constants/margin_left", 100)
			$MainMargin.set("theme_override_constants/margin_right", 100)

			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_left", 5)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_right", 5)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_top", 5)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_bottom", 5)
		else:
			$MainMargin.set("theme_override_constants/margin_left", 200)
			$MainMargin.set("theme_override_constants/margin_right", 200)

			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_left", 20)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_right", 20)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_top", 0)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_bottom", 20)

		if _is_mobile_web:
			$MainMargin.set("theme_override_constants/margin_left", $MainMargin.get("theme_override_constants/margin_left") * 0.25)
			$MainMargin.set("theme_override_constants/margin_right", $MainMargin.get("theme_override_constants/margin_right") * 0.25)

			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_left", $MainMargin/Panel/MarginContainer.get("theme_override_constants/margin_left") * 0.25)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_right", $MainMargin/Panel/MarginContainer.get("theme_override_constants/margin_right") * 0.25)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_top", $MainMargin/Panel/MarginContainer.get("theme_override_constants/margin_top") * 0.25)
			$MainMargin/Panel/MarginContainer.set("theme_override_constants/margin_bottom", $MainMargin/Panel/MarginContainer.get("theme_override_constants/margin_bottom") * 0.25)

func _on_fov_value_changed(value: float) -> void:
	Settings.camera_fov = value
	%FOVLabel.text = str(value)

func _on_limit_fps_item_selected(index: int) -> void:
	if index == 0:
		Settings.limit_fps = 0
	elif index == 1:
		Settings.limit_fps = 60
	elif index == 2:
		Settings.limit_fps = 45
	elif index == 3:
		Settings.limit_fps = 30
	elif index == 4:
		Settings.limit_fps = 24

func _on_v_sync_item_selected(index: int) -> void:
	if index == 0:
		Settings.vsync = true
	else:
		Settings.vsync = false


func _on_resolution_item_selected(index: int) -> void:
	if index == 0:
		Settings.resolution_scale = 1.0
	elif index == 1:
		Settings.resolution_scale = 1.05
	elif index == 2:
		Settings.resolution_scale = 1.5
	elif index == 3:
		Settings.resolution_scale = 2.0
	elif index == 4:
		Settings.resolution_scale = 3.0

func _on_window_mode_item_selected(index: int) -> void:
	if index == 0:
		Settings.window_mode = DisplayServer.WINDOW_MODE_WINDOWED
	elif index == 1:
		Settings.window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN













func _on_master_vol_value_changed(value: float) -> void:
	Settings.vol_master = value
	%MasterVolLabel2.text = str(int(value)) + "%"

func _on_music_vol_value_changed(value: float) -> void:
	Settings.vol_music = value
	%MusicVolLabel2.text = str(int(value)) + "%"

func _on_sfx_vol_value_changed(value: float) -> void:
	Settings.vol_sfx = value
	%SFXVolLabel2.text = str(int(value)) + "%"

func _on_wind_vol_value_changed(value: float) -> void:
	Settings.vol_wind = value
	%WindVolLabel2.text = str(int(value)) + "%"



func _on_shadow_res_item_selected(index: int) -> void:
	if index == 0:
		Settings.shadow_res = 1024
	elif index == 1:
		Settings.shadow_res = 2048
	elif index == 2:
		Settings.shadow_res = 4096


func _on_ssao_item_selected(index: int) -> void:
	if index == 0:
		Settings.ssao = true
	else:
		Settings.ssao = false









func _on_sens_value_changed(value: float) -> void:
	if value == 0:
		value = 1
	Settings.mouse_sensitivity = value
	%SensLabel2.text = str(int(value))
	if value > 100.0:
		%SensLabel2.modulate = Color.from_string("ffa3b7", Color.WHITE)
	else:
		%SensLabel2.modulate = Color.WHITE


func _on_ui_scale_item_selected(index: int) -> void:
	var scales = [Settings.UIScale.TINY, Settings.UIScale.SMALL, Settings.UIScale.NORMAL, Settings.UIScale.LARGE, Settings.UIScale.HUGE]
	if index >= 0 and index < scales.size():
		Settings.ui_scale = scales[index]


func _on_paint_filter_item_selected(index: int) -> void:
	if index == 0:
		Settings.disable_paint_screen_filter = false
	else:
		Settings.disable_paint_screen_filter = true


func _on_force_touch_controls_item_selected(index: int) -> void:
	if index == 0:
		Settings.use_touch_controls = false
	else:
		Settings.use_touch_controls = true


func _on_auto_turn_vehicles_item_selected(index: int) -> void:
	if index == 0:
		Settings.auto_turn_vehicles = false
	else:
		Settings.auto_turn_vehicles = true



func _on_paint_res_item_selected(index: int) -> void:
	if index == 0:
		Settings.paint_texture_res_k = 2
	elif index == 1:
		Settings.paint_texture_res_k = 4


func _on_surface_scatter_item_selected(index: int) -> void:
	if index == 0:
		Settings.disable_surface_scatters = false
	elif index == 1:
		Settings.disable_surface_scatters = true


func _on_performance_toggle_toggled(toggled_on: bool) -> void:
	_prioritize_performance(toggled_on)





func _prioritize_performance(enabled: bool):
	%PerformanceToggle.button_pressed = enabled

	if enabled:
		_saved_performance_settings = {
			"disable_surface_scatters": Settings.disable_surface_scatters,
			"disable_paint_screen_filter": Settings.disable_paint_screen_filter,
			"ssao": Settings.ssao,
			"shadow_res": Settings.shadow_res,
			"limit_fps": Settings.limit_fps
		}

		Settings.disable_surface_scatters = true
		Settings.disable_paint_screen_filter = true
		Settings.ssao = false
		Settings.shadow_res = 1024
		Settings.limit_fps = 45
	else:
		if not _saved_performance_settings.is_empty():
			Settings.disable_surface_scatters = _saved_performance_settings.get("disable_surface_scatters", Settings.disable_surface_scatters)
			Settings.disable_paint_screen_filter = _saved_performance_settings.get("disable_paint_screen_filter", Settings.disable_paint_screen_filter)
			Settings.ssao = _saved_performance_settings.get("ssao", Settings.ssao)
			Settings.shadow_res = _saved_performance_settings.get("shadow_res", Settings.shadow_res)
			Settings.limit_fps = _saved_performance_settings.get("limit_fps", Settings.limit_fps)
			_saved_performance_settings.clear()

	if surface_scatter: surface_scatter.disabled = enabled
	if paint_res: paint_res.disabled = enabled
	if paint_filter: paint_filter.disabled = enabled
	if ssao_btn: ssao_btn.disabled = enabled
	if shadow_btn: shadow_btn.disabled = enabled
	if fps_btn: fps_btn.disabled = enabled


func _on_exit_button_pressed() -> void:
	PauseManager.paused = false
