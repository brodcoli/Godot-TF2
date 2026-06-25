extends Control

var url_link: String = "N/A":
	get:
		return url_link
	set(value):
		url_link = value
		%URLLabel.text = url_link

func _ready() -> void:
	%NoBtn.pressed.connect(_on_no_pressed)
	%CopyBtn.pressed.connect(_on_copy_pressed)
	%YesBtn.pressed.connect(_on_yes_pressed)

func _process(delta: float) -> void:
	if visible:
		if get_window().size.x < 1000:
			$MainMargin/ColorRect/MarginContainer.scale = Vector2.ONE * 0.75
		else:
			$MainMargin/ColorRect/MarginContainer.scale = Vector2.ONE * 1.0

		if get_window().size.x < 1000:
			$MainMargin.set("theme_override_constants/margin_left", 0)
			$MainMargin.set("theme_override_constants/margin_right", 0)
		elif get_window().size.x < 1600:
			$MainMargin.set("theme_override_constants/margin_left", 150)
			$MainMargin.set("theme_override_constants/margin_right", 150)
		else:
			$MainMargin.set("theme_override_constants/margin_left", 420)
			$MainMargin.set("theme_override_constants/margin_right", 420)

func _on_no_pressed():
	PauseManager.paused = false
	visible = false

func _on_copy_pressed():
	if not url_link or url_link == "" or url_link == "N/A":
		return

	DisplayServer.clipboard_set(url_link)
	$ClipboardAnim.stop()
	$ClipboardAnim.play("play")

func _on_yes_pressed():
	if not url_link or url_link == "" or url_link == "N/A":
		return

	OS.shell_open(url_link)
