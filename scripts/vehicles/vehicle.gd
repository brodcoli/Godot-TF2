@tool
extends CharacterBody3D
class_name Vehicle

signal player_entered(player: Actor)
signal player_exited(player: Actor)
signal entered_water
signal exited_water

@export var seat_marker: Marker3D
@export var exit_points: Array[Marker3D]:
	set(ptr):
		exit_points = ptr
		update_configuration_warnings()

@export var max_speed: float = 30.0
@export var acceleration: float = 10.0
@export var friction: float = 5.0
@export var steering_sensitivity: float = 2.0
@export var steering_speed: float = 10.0

@export var apply_lateral_friction: bool = true
@export var lateral_friction: float = 50.0
@export var jump_force: float = 4.0


@export var STEP_DISTANCE := 1.0
@export var STEP_VELOCITY_THRESHOLD := 2.0
const step_sfx_vol := -10.0

var _distance_driven := 0.0
var _last_step_idx := -1
var _was_driving := false

var is_being_driven: bool = false
var driver: Actor = null
var current_input_dir: Vector2 = Vector2.ZERO
var input_jump: bool = false
var current_steering: float = 0.0
var last_ground_basis: Basis = Basis.IDENTITY
var engine_power: float = 0.0
var last_vertical_speed: float = 0.0
var _last_hit_wall_idx: int = -1

var water_bodies: Array = []
var in_water: bool = false

@export var air_friction: float = 0.06


var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if exit_points.is_empty():
		warnings.append("No exit points provided. The player will spawn at a fallback position above the vehicle.")
	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if exit_points.is_empty():
		assert(!exit_points.is_empty(), "Vehicle (" + name + ") does not have any exit points provided.")

	var water_areas = get_tree().get_nodes_in_group("water_body")
	for area in water_areas:
		if area is Area3D:
			area.body_entered.connect(_on_water_body_entered.bind(area))
			area.body_exited.connect(_on_water_body_exited.bind(area))

func _on_water_body_entered(body: Node3D, area: Area3D) -> void:
	if body == self:
		if water_bodies.is_empty():
			in_water = true
			entered_water.emit()
		if not water_bodies.has(area):
			water_bodies.append(area)

func _on_water_body_exited(body: Node3D, area: Area3D) -> void:
	if body == self:
		water_bodies.erase(area)
		if water_bodies.is_empty():
			in_water = false
			exited_water.emit()

func possess_vehicle(new_driver: Actor) -> void:
	driver = new_driver
	is_being_driven = true
	rotation.z = 0
	player_entered.emit(driver)

func unpossess_vehicle() -> void:
	var old_driver = driver
	driver = null
	is_being_driven = false
	current_input_dir = Vector2.ZERO
	input_jump = false
	player_exited.emit(old_driver)

func set_drive_input(input_dir: Vector2, jump: bool) -> void:
	current_input_dir = input_dir
	input_jump = jump

func get_best_exit_point(player: Actor) -> Vector3:
	var fallback_pos = global_position + Vector3(0, 2, 0)
	if exit_points.is_empty():
		return fallback_pos

	var head = player.head
	var look_dir = -head.global_transform.basis.z if head else -player.global_transform.basis.z
	var ref_pos = head.global_position if head else player.global_position

	var exit_points_sorted = []
	for marker in exit_points:
		if marker:
			var dir_to_marker = (marker.global_position - ref_pos).normalized()
			var dot = look_dir.dot(dir_to_marker)
			exit_points_sorted.append({"marker": marker, "dot": dot})

	exit_points_sorted.sort_custom(func(a, b): return a.dot > b.dot)

	var space_state = get_world_3d().direct_space_state
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.55, 1.9, 0.55)

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.exclude = [get_rid(), player.get_rid()]

	for entry in exit_points_sorted:
		var marker = entry["marker"]
		var ground_buffer := 0.05
		query.transform = Transform3D(Basis(), marker.global_position + Vector3(0, shape.size.y / 2.0 + ground_buffer, 0))
		var results = space_state.intersect_shape(query)

		if results.is_empty():
			var start_pos = seat_marker.global_position if seat_marker else global_position + Vector3(0, 1.0, 0)
			var target_pos = marker.global_position + Vector3(0, 0.1, 0)
			var ray_query = PhysicsRayQueryParameters3D.create(start_pos, target_pos)
			ray_query.exclude = [get_rid(), player.get_rid()]
			var ray_results = space_state.intersect_ray(ray_query)

			if ray_results.is_empty():
				return marker.global_position

	print("No available exit point found without collisions!")
	return fallback_pos

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not is_on_floor():
		var current_gravity = gravity * (0.2 if in_water else 1.0)
		velocity.y -= current_gravity * delta
		if in_water:
			velocity.y = move_toward(velocity.y, 0.0, 2.0 * delta)


	if is_being_driven:
		_process_driving(delta)
	else:
		engine_power = move_toward(engine_power, 0.0, 2.0 * delta)

		if is_on_floor() or in_water:

			var current_friction = friction * (2.0 if in_water else 1.0)
			var current_speed2D = Vector2(velocity.x, velocity.z)
			current_speed2D = current_speed2D.move_toward(Vector2.ZERO, current_friction * delta)
			velocity.x = current_speed2D.x
			velocity.z = current_speed2D.y

	if apply_lateral_friction and (is_on_floor() or in_water):
		var current_lateral_friction = lateral_friction * (0.5 if in_water else 1.0)
		var right_dir = global_transform.basis.x.normalized()
		var lateral_vel = right_dir * velocity.dot(right_dir)
		var new_lateral_vel = lateral_vel.move_toward(Vector3.ZERO, current_lateral_friction * delta)
		velocity = velocity - lateral_vel + new_lateral_vel

	var was_on_floor_last = is_on_floor()
	var pos_before = global_position
	var horiz_speed_before = Vector2(velocity.x, velocity.z).length()

	move_and_slide()


	var current_vertical_speed = (global_position.y - pos_before.y) / delta


	var horiz_speed_after = Vector2(velocity.x, velocity.z).length()
	var speed_lost = horiz_speed_before - horiz_speed_after
	if get_slide_collision_count() > 0 and speed_lost > 5.0:
		var col = get_slide_collision(0)
		var normal = col.get_normal()
		if is_on_wall():
			const HIT_VOL_HARD := -9.0
			const HIT_VOL_MED  := -18.0
			const HIT_VOL_SOFT := -23.0
			var vol: float

			if speed_lost > 18.0:
				vol = HIT_VOL_HARD
			elif speed_lost > 10.0:
				vol = HIT_VOL_MED
			else:
				vol = HIT_VOL_SOFT
			var pitch = randf_range(0.85, 1.1)
			_last_hit_wall_idx = AudioManager.play_rand("vehicle/metal_hit", global_position, vol, pitch, _last_hit_wall_idx)

	if was_on_floor_last and not is_on_floor():
		velocity.y = last_vertical_speed

	if is_on_floor():
		last_vertical_speed = current_vertical_speed

	var current_speed := Vector2(velocity.x, velocity.z).length()
	var is_driving_sfx = is_on_floor() and current_speed > STEP_VELOCITY_THRESHOLD
	if is_driving_sfx:
		var material = MaterialDetector.do_raycast(global_position + Vector3.UP*0.05, Vector3.DOWN, 2.0)
		if not _was_driving:
			_distance_driven = 0.0
			var pitch = randf_range(0.9, 1.1)
			_last_step_idx = AudioManager.play_rand("materials/" + material.to_lower(), global_position, step_sfx_vol - 5.0, pitch, _last_step_idx, true)

		_distance_driven += current_speed * delta
		if _distance_driven >= STEP_DISTANCE:
			_distance_driven = 0.0
			var pitch = randf_range(0.9, 1.1)
			_last_step_idx = AudioManager.play_rand("materials/" + material.to_lower(), global_position, step_sfx_vol, pitch, _last_step_idx, true)
	else:
		_distance_driven = 0.0

	_was_driving = is_driving_sfx

func _process_driving(delta: float) -> void:
	var current_max_speed = max_speed * (0.4 if in_water else 1.0)
	var current_acceleration = acceleration * (0.3 if in_water else 1.0)

	if input_jump and is_on_floor():
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		var current_jump_force: float = max((horizontal_speed / current_max_speed) * jump_force, 0.6)
		velocity.y = current_jump_force
		last_vertical_speed = current_jump_force

	var forward_dir = -global_transform.basis.z
	var is_reversing = velocity.dot(forward_dir) < 0

	var target_turn_dir = current_input_dir.x
	if Settings.auto_turn_vehicles and driver and driver.head and current_input_dir.y != 0:
		var diff = angle_difference(global_rotation.y, driver.head.global_rotation.y)
		if is_reversing:
			target_turn_dir += clamp(diff * 2.0, -1.0, 1.0)
		else:
			target_turn_dir += clamp(-diff * 2.0, -1.0, 1.0)

	current_steering = move_toward(current_steering, target_turn_dir, steering_speed * delta)
	var turn_dir = current_steering
	var accel_input = -current_input_dir.y

	if accel_input != 0:
		var target_velocity = forward_dir * accel_input * current_max_speed
		if is_reversing:
			target_velocity *= 0.3

		var current_vel2D = Vector2(velocity.x, velocity.z)
		var target_vel2D = Vector2(target_velocity.x, target_velocity.z)
		current_vel2D = current_vel2D.move_toward(target_vel2D, current_acceleration * delta)
		velocity.x = current_vel2D.x
		velocity.z = current_vel2D.y

		var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
		engine_power = clamp(horizontal_speed / current_max_speed, 0.0, 1.0)
	else:
		engine_power = move_toward(engine_power, 0.0, 1.0 * delta)
		if is_on_floor() or in_water:

			var current_friction = friction * (2.0 if in_water else 1.0)
			var current_speed2D = Vector2(velocity.x, velocity.z)
			current_speed2D = current_speed2D.move_toward(Vector2.ZERO, current_friction * delta)
			velocity.x = current_speed2D.x
			velocity.z = current_speed2D.y


	var current_horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var speed_mult = min(current_horizontal_speed / 5.0, 1.0)
	if current_horizontal_speed > 0.0:


		var steering_mult = -1.0 if is_reversing else 1.0
		rotate_object_local(Vector3.UP, -turn_dir * steering_sensitivity * delta * steering_mult * speed_mult)

	if is_on_floor():
		var normal = get_floor_normal()
		var current_forward = -global_transform.basis.z
		var target_basis = global_transform.basis
		if abs(current_forward.dot(normal)) < 0.99:
			var new_x = current_forward.cross(normal).normalized()
			var new_z = new_x.cross(normal).normalized()
			target_basis = Basis(new_x, normal, new_z)

		global_transform.basis = global_transform.basis.slerp(target_basis, 7.0 * delta).orthonormalized()

		last_ground_basis = target_basis
	else:

		global_transform.basis = global_transform.basis.slerp(last_ground_basis, 5.0 * delta).orthonormalized()

		var current_air_friction = air_friction * (15.0 if in_water else 1.0)
		var horiz_vel = Vector2(velocity.x, velocity.z)
		horiz_vel = horiz_vel.move_toward(Vector2.ZERO, current_air_friction * delta)
		velocity.x = horiz_vel.x
		velocity.z = horiz_vel.y
