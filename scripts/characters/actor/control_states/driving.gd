extends State

@onready var actor: Actor = $"../.."

var saved_collision_layer: int
var saved_collision_mask: int
var last_vehicle_rot_y: float = 0.0

var _rel_head_pos: Vector3

func state_enter():
	if not Settings.use_touch_controls and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	saved_collision_layer = actor.collision_layer
	saved_collision_mask = actor.collision_mask
	actor.collision_layer = 0
	actor.collision_mask = 0

	_rel_head_pos = actor.head.position if actor.head else Vector3.ZERO
	if actor.head:
		actor.head.top_level = true

	if actor.current_vehicle:
		last_vehicle_rot_y = actor.current_vehicle.rotation.y

func state_exit():
	actor.collision_layer = saved_collision_layer
	actor.collision_mask = saved_collision_mask


	if actor.head:
		var y_rot_diff = actor.head.global_rotation.y - actor.global_rotation.y
		actor.head.top_level = false
		actor.head.position = _rel_head_pos
		actor.global_rotation.y = actor.head.global_rotation.y
		actor.head.global_rotation.y -= y_rot_diff

func state_process(delta: float):
	if actor.head:
		actor.head.global_position = actor.global_position + _rel_head_pos

	var look_delta := actor.consume_look_delta()
	if look_delta != Vector2.ZERO and not actor.command.movement_disabled and actor.head:
		actor.head.rotation.y -= look_delta.x
		actor.head.rotation.x -= look_delta.y
		actor.head.rotation.x = clamp(actor.head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		actor.head.rotation.z = 0.0

	if actor.command.is_exit_vehicle_just_pressed() and not actor.command.movement_disabled:
		actor.exit_vehicle()

func state_physics_process(delta: float):
	if actor.current_vehicle:

		if actor.current_vehicle.seat_marker:
			actor.global_position = actor.current_vehicle.seat_marker.global_position
			var current_vehicle_rot_y = actor.current_vehicle.rotation.y
			var rot_diff = angle_difference(last_vehicle_rot_y, current_vehicle_rot_y)
			if not Settings.auto_turn_vehicles and actor.head:
				actor.head.global_rotation.y += rot_diff * 0.2
			actor.global_rotation.y = current_vehicle_rot_y
			last_vehicle_rot_y = current_vehicle_rot_y

		if not actor.command.movement_disabled:
			actor.current_vehicle.set_drive_input(actor.command.move_dir, actor.command.is_jump_just_pressed())
		else:
			actor.current_vehicle.set_drive_input(Vector2.ZERO, false)

func state_input(event: InputEvent):
	pass
