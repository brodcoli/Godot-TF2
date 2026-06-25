extends State

@export var SWIM_ACCELERATION := 8.0
@export var SWIM_FRICTION := 0.98
@export var SWIM_UP_VELOCITY := 0.4
@export var FLOAT_FORCE := 2.0

@onready var actor: Actor = $"../.."

func state_enter():
	if not Settings.use_touch_controls:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not actor.exited_water.is_connected(_on_exited_water):
		actor.exited_water.connect(_on_exited_water)
	if actor.water_bodies.is_empty():
		_on_exited_water()

func state_exit():
	if actor.exited_water.is_connected(_on_exited_water):
		actor.exited_water.disconnect(_on_exited_water)

func _on_exited_water():
	actor.control_state_machine.change_state("walking")

func state_process(delta: float):
	var look_delta := actor.consume_look_delta()
	if look_delta != Vector2.ZERO and not actor.command.movement_disabled:
		actor.rotate_y(-look_delta.x)
		if actor.head:
			actor.head.rotate_x(-look_delta.y)
			actor.head.rotation.x = clamp(actor.head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if actor.command.is_use_just_pressed() and not actor.command.movement_disabled:
		if actor.look_ray and actor.look_ray.is_colliding():
			var collider = actor.look_ray.get_collider()
			if collider is Vehicle:
				actor.enter_vehicle(collider)

func state_physics_process(delta: float):

	actor.velocity.y += FLOAT_FORCE * delta


	var input_dir := actor.command.move_dir

	if actor.command.movement_disabled:
		input_dir = Vector2.ZERO


	var direction := (actor.get_look_reference().global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		actor.velocity.x += direction.x * SWIM_ACCELERATION * delta
		actor.velocity.y += direction.y * SWIM_ACCELERATION * delta
		actor.velocity.z += direction.z * SWIM_ACCELERATION * delta


	actor.velocity.x *= SWIM_FRICTION
	actor.velocity.y *= SWIM_FRICTION
	actor.velocity.z *= SWIM_FRICTION


	if actor.command.jump_held and not actor.command.movement_disabled:
		actor.velocity.y += SWIM_UP_VELOCITY * delta * 10.0

	actor.move_and_slide()

func state_input(event: InputEvent):
	pass
