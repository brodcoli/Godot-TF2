extends Node3D

const MAX_LOOK_ANGLE := deg_to_rad(89.0)
const BODY_FOLLOW_LOOK_ANGLE := deg_to_rad(89.0)
const BODY_TURN_SPEED := 20.0
const BODY_TURN_MIN_SPEED := 0.2
const BODY_YAW_OFFSET := PI
const FIRE_LAUNCHER_REQUEST_PATH := "parameters/FireLauncher/request"

var actor: Actor
var _local_position_offset := Vector3.ZERO
var _body_yaw := 0.0

@export var held_item_attachment: Node3D

@onready var animation_tree: AnimationTree = $AnimationTree

func setup_actor_animation(new_actor: Actor, _bridge: ActorAnimationBridge) -> void:
	actor = new_actor
	_local_position_offset = position
	_body_yaw = actor.global_rotation.y
	top_level = true
	global_rotation.y = _body_yaw + BODY_YAW_OFFSET
	animation_tree.active = true

func actor_motion(info: Dictionary) -> void:
	_follow_actor(info)
	
	animation_tree.set("parameters/BlendSpace1D/blend_position", info.get("idle_run", -1.0))
	animation_tree.set("parameters/BlendSpace2D/blend_position", _look_blend(info))

func actor_action(action: StringName, _info: Dictionary, _payload: Variant) -> void:
	if action == &"item_used":
		animation_tree.set(FIRE_LAUNCHER_REQUEST_PATH, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
func _follow_actor(info: Dictionary) -> void:
	if actor == null:
		return

	global_position = actor.to_global(_local_position_offset)

	var velocity: Vector3 = info.get("velocity", Vector3.ZERO)
	velocity.y = 0.0
	if velocity.length() > BODY_TURN_MIN_SPEED:
		var target_yaw := atan2(-velocity.x, -velocity.z)
		_body_yaw = lerp_angle(_body_yaw, target_yaw, get_process_delta_time() * BODY_TURN_SPEED)

	_follow_look_yaw()
	global_rotation.y = _body_yaw + BODY_YAW_OFFSET

func _follow_look_yaw() -> void:
	var look_yaw := actor.get_look_reference().global_rotation.y
	var yaw_difference := angle_difference(_body_yaw, look_yaw)
	if absf(yaw_difference) <= BODY_FOLLOW_LOOK_ANGLE:
		return

	_body_yaw = look_yaw - signf(yaw_difference) * BODY_FOLLOW_LOOK_ANGLE

func _look_blend(info: Dictionary) -> Vector2:
	if actor == null or actor.head == null:
		var look: Vector2 = info.get("look", Vector2.ZERO)
		return look

	#var yaw := angle_difference(_body_yaw, actor.get_look_reference().global_rotation.y)
	
	return Vector2(clampf((actor.head.global_rotation.y - _body_yaw) / MAX_LOOK_ANGLE, -1.0, 1.0)*-1.0, clampf(actor.head.rotation.x / MAX_LOOK_ANGLE, -1.0, 1.0))
