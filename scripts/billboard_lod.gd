extends StaticBody3D

@export var model: Node3D
@export var model_lod_med: Node3D
@export var model_lod_low: Node3D
@export var distance_to_lod_med: float = 80.0
@export var distance_to_lod_low: float = 300.0

func _process(_delta: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	var dist = global_position.distance_to(cam.global_position)

	if dist >= distance_to_lod_low:
		if model: model.visible = false
		if model_lod_med: model_lod_med.visible = false
		if model_lod_low: model_lod_low.visible = true
	elif dist >= distance_to_lod_med:
		if model: model.visible = false
		if model_lod_med: model_lod_med.visible = true
		if model_lod_low: model_lod_low.visible = false
	else:
		if model: model.visible = true
		if model_lod_med: model_lod_med.visible = false
		if model_lod_low: model_lod_low.visible = false
