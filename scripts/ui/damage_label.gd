extends Control

var amount: float:
	set(value):
		amount = value
		$Label.text = "-" + str(int(amount))

var location: Vector3

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_screen_position()
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	queue_free()

func _process(_delta: float) -> void:
	_update_screen_position()

func _update_screen_position() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not location.is_finite():
		visible = false
		return

	if camera.is_position_behind(location):
		visible = false
		return

	visible = true
	position = camera.unproject_position(location)# - $Label.size * 0.5
