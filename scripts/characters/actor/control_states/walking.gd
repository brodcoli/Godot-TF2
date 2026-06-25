extends State

const DEBUG_PRINT_PLAYER_VELOCITY = false
const DEBUG_PRINT_PLAYER_JUMP_PEAK_HEIGHT = false


@export var JUMP_VELOCITY := 7.2
@export var GROUND_ACCELERATION := 91.5
@export var AIR_ACCELERATION := 8.0
@export var GROUND_FRICTION := 0.755
@export var AIR_FRICTION := 0.998
@export var MAX_MOVE_VELOCITY := 4.7
@export var STEP_DISTANCE := 2.0
@export var STEP_VELOCITY_THRESHOLD := 4.0










const step_sfx_vol := -17.0
const FOOTSTEP_AUDIO_PREDICTION_TIME := 0.1
const HAMMER_UNITS_PER_METER := 39.3701
const TF2_GRAVITY_HU_PER_SECOND := 800.0
const TF2_FALL_DAMAGE_THRESHOLD_HU_PER_SECOND := 650.0
const TF2_FALL_DAMAGE_HEALTH_DIVISOR_HU_PER_SECOND := 6000.0

var _distance_walked := 0.0
var _last_footstep_idx := -1
var _max_air_height := 0.0
var _debug_tracking_jump_peak := false
var _debug_jump_start_height := 0.0
var _debug_jump_peak_height := 0.0
var _was_walking := false

@export var mat_settings: Dictionary = {
	"ICE": {
		"friction": 0.97,
		"acceleration": 13.0
	}
}

@onready var actor: Actor = $"../.."
@onready var first_person_camera: Camera3D = actor.get_node_or_null("Head/CamFirst")

@export var gravity: float = TF2_GRAVITY_HU_PER_SECOND / HAMMER_UNITS_PER_METER
@export var fall_damage_random_spread := true

func _get_predicted_footstep_position() -> Vector3:
	return actor.global_position + actor.velocity * FOOTSTEP_AUDIO_PREDICTION_TIME

func _is_first_person_camera_active() -> bool:
	return first_person_camera != null and actor.get_viewport().get_camera_3d() == first_person_camera

func _should_print_player_jump_peak_height() -> bool:
	return DEBUG_PRINT_PLAYER_JUMP_PEAK_HEIGHT and actor.is_player_controlled

func state_enter():
	if not Settings.use_touch_controls and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not actor.entered_water.is_connected(_on_entered_water):
		actor.entered_water.connect(_on_entered_water)
	if actor.water_bodies.size() > 0:
		_on_entered_water()

func state_exit():
	if actor.entered_water.is_connected(_on_entered_water):
		actor.entered_water.disconnect(_on_entered_water)
	_debug_tracking_jump_peak = false

func _on_entered_water():
	actor.control_state_machine.change_state("swimming")

var prev_pos_h := Vector3.ZERO
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

	if DEBUG_PRINT_PLAYER_VELOCITY and owner.is_in_group("player"):
		var pos_h = actor.global_position * Vector3(1, 0, 1)
		var diff_h = pos_h - prev_pos_h
		print(diff_h.length() * delta * 60.0 * 60.0)

		prev_pos_h = pos_h


func state_physics_process(delta: float):
	var was_on_floor = actor.is_on_floor()

	if not actor.is_on_floor():
		actor.velocity.y -= gravity * 0.5 * delta
		_max_air_height = max(_max_air_height, actor.global_position.y)
		if _debug_tracking_jump_peak:
			_debug_jump_peak_height = max(_debug_jump_peak_height, actor.global_position.y)
	else:
		_max_air_height = actor.global_position.y



	var input_dir := actor.command.move_dir

	if actor.command.movement_disabled:
		input_dir = Vector2.ZERO
	var direction := (actor.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_friction := GROUND_FRICTION
	var current_acceleration := GROUND_ACCELERATION
	var material := ""
	if actor.is_on_floor():
		material = MaterialDetector.do_raycast(actor.global_position + Vector3.UP*0.05, Vector3.DOWN, 2.0)
		if material in mat_settings:
			current_friction = mat_settings[material]["friction"]
			current_acceleration = mat_settings[material]["acceleration"]
	else:
		current_friction = AIR_FRICTION
		current_acceleration = AIR_ACCELERATION

	if direction:
		var horizontal_velocity := Vector3(actor.velocity.x, 0.0, actor.velocity.z)
		var speed_in_move_direction := horizontal_velocity.dot(direction)
		var max_pre_friction_move_speed := MAX_MOVE_VELOCITY / current_friction if current_friction > 0.0 else MAX_MOVE_VELOCITY
		var available_move_speed := max_pre_friction_move_speed - speed_in_move_direction
		if available_move_speed > 0.0:
			var added_move_speed = min(current_acceleration * delta, available_move_speed)
			actor.velocity.x += direction.x * added_move_speed
			actor.velocity.z += direction.z * added_move_speed

	actor.velocity.x *= current_friction
	actor.velocity.z *= current_friction

	var current_speed := Vector2(actor.velocity.x, actor.velocity.z).length()
	var is_walking = actor.is_on_floor() and current_speed > STEP_VELOCITY_THRESHOLD
	if is_walking:
		if not _was_walking:
			_distance_walked = 0.0
			var pitch = randf_range(0.9, 1.1)
			_last_footstep_idx = AudioManager.play_rand("materials/" + material.to_lower(), _get_predicted_footstep_position(), step_sfx_vol - 5.0, pitch, _last_footstep_idx, _is_first_person_camera_active())

		_distance_walked += current_speed * delta
		if _distance_walked >= STEP_DISTANCE:
			_distance_walked = 0.0
			var pitch = randf_range(0.9, 1.1)
			_last_footstep_idx = AudioManager.play_rand("materials/" + material.to_lower(), _get_predicted_footstep_position(), step_sfx_vol, pitch, _last_footstep_idx, _is_first_person_camera_active())
	else:
		_distance_walked = 0.0

	_was_walking = is_walking


	if actor.command.is_jump_just_pressed() and actor.is_on_floor() and not actor.command.movement_disabled:
		if _should_print_player_jump_peak_height():
			_debug_tracking_jump_peak = true
			_debug_jump_start_height = actor.global_position.y
			_debug_jump_peak_height = actor.global_position.y
		actor.velocity.y += JUMP_VELOCITY
		var _jump_idx = AudioManager.play_rand("materials/" + material.to_lower(), actor.global_position, step_sfx_vol, 1.1, -1)

	var landing_downward_speed := maxf(-actor.velocity.y, 0.0)
	actor.move_and_slide()

	if not actor.is_on_floor():
		actor.velocity.y -= gravity * 0.5 * delta
		if _debug_tracking_jump_peak:
			_debug_jump_peak_height = max(_debug_jump_peak_height, actor.global_position.y)

	if actor.is_on_floor() and not was_on_floor:
		if _debug_tracking_jump_peak:
			var jump_peak_height := maxf(_debug_jump_peak_height - _debug_jump_start_height, 0.0)
			print("Player jump peak height: %.3f m" % jump_peak_height)
			_debug_tracking_jump_peak = false
		_distance_walked = 0.0
		var landing_mat = MaterialDetector.do_raycast(actor.global_position + Vector3.UP*0.05, Vector3.DOWN, 2.0)
		var pitch = randf_range(0.9, 1.1)
		var drop_dist = _max_air_height - actor.global_position.y
		var land_vol = clamp(step_sfx_vol + (drop_dist * 20.0), step_sfx_vol, 40.0)
		_last_footstep_idx = AudioManager.play_rand("materials/" + landing_mat.to_lower(), actor.global_position, land_vol, 1.1, _last_footstep_idx)
		_apply_fall_damage(landing_downward_speed)


func _apply_fall_damage(downward_speed_meters_per_second: float) -> void:
	var downward_speed_hu_per_second := downward_speed_meters_per_second * HAMMER_UNITS_PER_METER
	if downward_speed_hu_per_second <= TF2_FALL_DAMAGE_THRESHOLD_HU_PER_SECOND:
		return

	var damage := float(actor.max_health) * downward_speed_hu_per_second / TF2_FALL_DAMAGE_HEALTH_DIVISOR_HU_PER_SECOND
	if fall_damage_random_spread:
		damage *= randf_range(0.8, 1.2)

	actor.hurt(roundi(damage), null, actor.global_position)


func state_input(event: InputEvent):
	pass
