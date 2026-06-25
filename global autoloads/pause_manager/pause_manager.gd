extends Node

signal pause_changed(is_paused: bool)

@onready var _pause_screen: Control = $CanvasLayer/PauseScreen


var disable_auto_pausing = false

var _waiting_for_user = true

var paused: bool = false:
	get:
		return paused
	set(value):
		paused = value
		if paused:
			_pause()
		else:
			_unpause()
		pause_changed.emit(paused)

func show_link_window(url_link: String):
	paused = true
	$CanvasLayer/PauseScreen/VisitLinkScreen.url_link = url_link
	$CanvasLayer/PauseScreen/VisitLinkScreen.visible = true

func _ready() -> void:
	paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if _waiting_for_user:
		if event is InputEventMouseMotion:
			return
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_waiting_for_user = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if OS.has_feature("web"):
			while Input.is_action_pressed("ui_cancel"):
				await get_tree().create_timer(0.05).timeout
		paused = not paused

func _pause():
	get_tree().paused = true
	if not Settings.use_touch_controls and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_pause_screen.visible = true

func _unpause():
	get_tree().paused = false
	if not Settings.use_touch_controls and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_pause_screen.visible = false


func _process(delta: float) -> void:
	if Settings.use_touch_controls and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if not _waiting_for_user and not disable_auto_pausing and not Settings.use_touch_controls:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not paused:
			paused = true
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and paused:
			paused = false











func _on_resume_btn_pressed() -> void:
	if paused:
		paused = false
