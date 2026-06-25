extends Node3D

@export var radius := 20.0
@export var height_offset := 1.5

var locator := SpatialVisibilityLocator.new()

func _ready() -> void:
	add_child(locator)
	locator.search_radius = radius

	while true:
		await get_tree().create_timer(2.0).timeout
		await _teleport_to_hidden_point()

func _teleport_to_hidden_point() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	locator.search_radius = radius
	locator.exclude = [player.get_rid()]

	var point = await locator.find_position(
		player.global_position,
		height_offset,
		[player.head.global_position],
		SpatialVisibilityLocator.VisibilityMode.HIDDEN_FROM_ALL_TARGETS
	)

	if point is Vector3:
		global_position = point
