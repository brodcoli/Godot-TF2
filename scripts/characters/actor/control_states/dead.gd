extends State

@onready var actor: Actor = $"../.."

var body: RigidBody3D
var head_transform: Transform3D

var _auto_behavior_was_enabled := false

func state_enter():
	%DeadUIMain.visible = true


	if actor.cam_first.current or actor.cam_third.current:
		actor.cam_first.current = false
		actor.cam_third.make_current()


	actor.entered_dead_state.emit()
	actor.command.inputs_disabled = true
	actor.command.clear_input_values()
	actor.inventory_hold_point.visible = false
	actor.set_view_model_visible(false)
	var held_item := actor.get_selected_inventory_item()
	if held_item:
		held_item.visible = false
	_auto_behavior_was_enabled = actor.auto_behavior.enabled
	actor.auto_behavior.enabled = false
	if actor.head == null:
		return

	head_transform = actor.head.transform
	var head_global := actor.head.global_transform

	body = RigidBody3D.new()
	body.name = "DeadHeadBody"
	actor.get_parent().add_child(body)
	body.global_transform = head_global

	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 0.12
	body.add_child(shape)

	if actor.character_definition and actor.character_definition.dead_head_model_scene:
		body.add_child(actor.character_definition.dead_head_model_scene.instantiate())

	body.continuous_cd = true
	body.angular_damp = 2.0
	var phys_mat := PhysicsMaterial.new()
	phys_mat.friction = 1.0
	phys_mat.bounce = 0.3
	body.physics_material_override = phys_mat
	body.apply_torque_impulse(Vector3(randf(), randf(), randf()).normalized() * 0.04)
	body.apply_central_impulse(Vector3.UP * 4.0 + actor.velocity * Vector3(0.5, 0.4, 0.5))

	actor.head.top_level = true
	actor.global_position = Vector3(0, -99999, 0)




func state_exit():
	%DeadUIMain.visible = false
	actor.inventory_hold_point.visible = true
	actor.set_view_model_visible(actor.is_in_group("player"))
	if actor.cam_first.current or actor.cam_third.current:
		actor.cam_first.current = true
		actor.cam_third.current = false
	var held_item := actor.get_selected_inventory_item()
	if held_item:
		held_item.visible = true
		actor.refresh_held_inventory_item_parent()
	actor.head.top_level = false
	actor.head.transform = head_transform
	if body:
		body.queue_free()
	actor.command.inputs_disabled = false
	actor.auto_behavior.enabled = _auto_behavior_was_enabled

func state_process(_delta: float):
	actor.command.inputs_disabled = true
	actor.command.clear_input_values(false)

	actor.head.global_position = body.global_position
	var look_delta := actor.consume_look_delta()

	if look_delta != Vector2.ZERO:
		actor.head.rotation.y -= look_delta.x
		actor.head.rotation.x -= look_delta.y
		actor.head.rotation.x = clamp(actor.head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		actor.head.rotation.z = 0.0

func state_physics_process(_delta: float):
	actor.velocity = Vector3.ZERO
