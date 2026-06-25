extends Node
class_name SetupWaterBodies

@export var map_node: Node3D

@export var name_identifier: String = "(WATER)"

func _ready() -> void:
	if not map_node:
		return
	_find_and_setup_water_bodies(map_node)

func _find_and_setup_water_bodies(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and name_identifier in child.name:
			_setup_water_body(child)
		_find_and_setup_water_bodies(child)

func _setup_water_body(mesh_instance: MeshInstance3D) -> void:
	if not is_equal_approx(mesh_instance.scale.x, mesh_instance.scale.y) or not is_equal_approx(mesh_instance.scale.y, mesh_instance.scale.z):
		push_error("Water body mesh instance '%s' has a non-uniform scale: %s" % [mesh_instance.name, mesh_instance.scale])

	var area := Area3D.new()
	area.add_to_group("water_body")
	mesh_instance.add_child(area)

	if mesh_instance.mesh:
		var col_shape := CollisionShape3D.new()
		col_shape.shape = mesh_instance.mesh.create_convex_shape()
		area.add_child(col_shape)

	area.body_entered.connect(_on_water_body_entered)

func _on_water_body_entered(body: Node3D) -> void:
	if body is RigidBody3D or body is CharacterBody3D:
		var velocity: Vector3
		if body is RigidBody3D:
			velocity = body.linear_velocity
		else:
			velocity = body.velocity

		var speed = velocity.length()

		if speed > 8.0:
			AudioManager.play_rand("water/splash_big", body.global_position)
		elif speed > 1.0:
			AudioManager.play_rand("water/splash_small", body.global_position)
