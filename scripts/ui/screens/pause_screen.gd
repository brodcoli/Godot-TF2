extends Control

func _ready() -> void:
	$SettingsScreen.visible = false
	$VisitLinkScreen.visible = false

func _process(delta: float) -> void:
	if visible and get_window().size.y <= 780:
		$Info1.scale = Vector2.ONE * min(pow(get_window().size.y / 780.0, 1.8), 1.0)

func _on_settings_btn_pressed() -> void:
	$SettingsScreen.visible = not $SettingsScreen.visible

func _on_visibility_changed() -> void:
	if not visible:
		$SettingsScreen.visible = false
		$VisitLinkScreen.visible = false
