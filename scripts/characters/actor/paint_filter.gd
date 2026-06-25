extends MeshInstance3D


func _process(delta: float) -> void:
	visible = not Settings.disable_paint_screen_filter
