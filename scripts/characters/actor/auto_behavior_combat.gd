extends Node
class_name AutoBehaviorCombat

@onready var auto_behavior: AutoBehavior = get_parent()
var actor: Actor = null

var target: Actor = null
var last_seen := Vector3.ZERO
var has_move_goal := false
var move_goal := Vector3.ZERO
var move_avoidance_radius := 0.0
var _look_wander_time := 0.0
var _look_wander := Vector3.FORWARD
var _target_position_refresh_time := 0.0
var _aim_deviation_time := 0.0
var _aim_deviation := Vector3.ZERO
var _rocket_jump_target: Actor = null
var _rocket_jump_active := false
var _rocket_jump_fired := false
var _rocket_jump_restore_head_rotation := Vector3.ZERO
const IDLE_LOOK_TURN_SPEED := 5.0
const ROCKET_JUMP_LOOK_SPEED := 7.0#35.0
const TARGET_ACQUIRE_DOT := 0.0

func tick(delta: float) -> void:
	if not _resolve_actor():
		return
	has_move_goal = false
	move_avoidance_radius = 0.0
	_update_target()

	if _update_resource_move_goal():
		actor.command.use_held = false
		_look_idle(delta)
		return

	if target:
		var visible := can_see(target) and _is_in_forward_half(target)
		if visible:
			_update_last_seen_position(delta)
		if _try_rocket_jump(delta):
			actor.command.use_held = false
			_update_move_goal()
			return
		_look_at(_deviated_aim_position(last_seen, delta), delta, _combat_values().aim_turn_speed)
		actor.command.use_held = true
		_update_move_goal()
	else:
		actor.command.use_held = false
		_rocket_jump_target = null
		_rocket_jump_active = false
		_reset_aim_deviation()
		_look_idle(delta)

func engage(enemy: Actor) -> void:
	if is_enemy(enemy):
		target = enemy
		last_seen = _aim_position(enemy)
		_reset_target_position_refresh()
		_reset_aim_deviation()

func is_enemy(other: Actor) -> bool:
	if not _resolve_actor() or other == null or other == actor or other.health <= 0:
		return false
	return actor.team == null or other.team == null or actor.team != other.team

func _resolve_actor() -> bool:
	if actor == null and auto_behavior:
		actor = auto_behavior.actor
	return actor != null

func can_see(other: Actor) -> bool:
	var from := actor.get_look_reference().global_position
	var look_reference := other.get_look_reference()
	var to := look_reference.global_position if look_reference else other.global_position
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_rid(actor)]
	query.collide_with_bodies = true
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	return collider == other or (collider != null and other.is_ancestor_of(collider))

func _is_in_forward_half(other: Actor) -> bool:
	var look_reference := actor.get_look_reference()
	var other_reference := other.get_look_reference()
	var from := look_reference.global_position
	var to := other_reference.global_position
	var flat_to_other := to - from
	flat_to_other.y = 0.0
	if flat_to_other.length_squared() <= 0.0001:
		return true
	var forward := -look_reference.global_transform.basis.z if look_reference else -actor.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return true
	return forward.normalized().dot(flat_to_other.normalized()) >= TARGET_ACQUIRE_DOT

func _update_target() -> void:
	var values := _combat_values()
	if target and (not is_instance_valid(target) or target.health <= 0 or actor.global_position.distance_to(target.global_position) > values.disengage_distance):
		target = null
		_rocket_jump_target = null
		_rocket_jump_active = false
		_reset_target_position_refresh()
		_reset_aim_deviation()
	if target:
		return
	for node in get_tree().get_nodes_in_group("actors"):
		var enemy := node as Actor
		if is_enemy(enemy) and actor.global_position.distance_to(enemy.global_position) <= values.engage_distance and _is_in_forward_half(enemy) and can_see(enemy):
			engage(enemy)
			return

func _update_move_goal() -> void:
	var values := _combat_values()
	if float(actor.health) / float(actor.max_health) >= 0.4 and actor.global_position.distance_to(target.global_position) <= values.close_distance:
		has_move_goal = true
		move_goal = last_seen
		move_avoidance_radius = values.close_avoidance_radius

func _update_resource_move_goal() -> bool:
	if not _low_resources():
		return false
	var pack := _nearest_health_pack()
	if pack == null:
		return false
	has_move_goal = true
	move_goal = pack.global_position
	return true

func _low_resources() -> bool:
	if float(actor.health) / float(actor.max_health) <= 0.2:
		return true
	return auto_behavior.selected_item_resources_low(0.2)

func _try_rocket_jump(delta: float) -> bool:
	if _rocket_jump_active:
		_update_rocket_jump(delta)
		return true

	var values := _combat_values()
	if not values.enable_rocket_jumping:
		return false
	if target.global_position.y - actor.global_position.y <= values.rocket_jump_height_difference:
		_rocket_jump_target = null
		return false
	if target == _rocket_jump_target or actor.health < values.rocket_jump_min_health:
		return false

	var item = actor.get_selected_inventory_item()
	if item == null or item.clip <= 0 or item.time_since_last_fire < item.FIRE_DELAY or actor.head == null:
		return false

	_rocket_jump_active = true
	_rocket_jump_fired = false
	_rocket_jump_restore_head_rotation = actor.head.rotation
	_update_rocket_jump(delta)
	return true

func _update_rocket_jump(delta: float) -> void:
	var target_pitch := deg_to_rad(-89)
	var restore_pitch := _rocket_jump_restore_head_rotation.x
	var pitch := target_pitch if not _rocket_jump_fired else restore_pitch

	actor.head.rotation.x = move_toward(actor.head.rotation.x, pitch, delta * ROCKET_JUMP_LOOK_SPEED)
	actor.head.rotation.z = 0.0

	if not _rocket_jump_fired and absf(actor.head.rotation.x - target_pitch) < 0.02:
		actor.look_ray.force_raycast_update()
		actor.command.press_jump_once()
		actor.use_held_selected_inventory_item()
		_rocket_jump_fired = true
		_rocket_jump_target = target

	if _rocket_jump_fired and absf(actor.head.rotation.x - restore_pitch) < 0.02:
		actor.head.rotation = _rocket_jump_restore_head_rotation
		_rocket_jump_active = false

func _look_idle(delta: float) -> void:
	_look_wander_time -= delta
	if _look_wander_time <= 0.0:
		_look_wander_time = randf_range(0.6, 1.8)
		var move := actor.global_transform.basis * Vector3(actor.command.move_dir.x, 0.0, actor.command.move_dir.y)
		_look_wander = (move + Vector3(randf_range(-0.6, 0.6), randf_range(-0.15, 0.15), randf_range(-0.6, 0.6))).normalized()
		if _look_wander.length_squared() == 0.0:
			_look_wander = -actor.global_transform.basis.z
	_look_at(actor.get_look_reference().global_position + _look_wander * 10.0, delta, IDLE_LOOK_TURN_SPEED)

func _look_at(pos: Vector3, delta: float, speed: float) -> void:
	var flat := pos - actor.global_position
	flat.y = 0.0
	if flat.length_squared() > 0.0001:
		actor.global_rotation.y = lerp_angle(actor.global_rotation.y, atan2(-flat.x, -flat.z), delta * speed)
	if actor.head:
		var local := actor.head.to_local(pos)
		actor.head.rotation.x = lerp_angle(actor.head.rotation.x, clampf(atan2(local.y, -local.z), deg_to_rad(-89), deg_to_rad(89)), delta * speed)

func _deviated_aim_position(pos: Vector3, delta: float) -> Vector3:
	var from := actor.get_look_reference().global_position
	var to_target := pos - from
	var distance := to_target.length()
	if distance <= 0.001:
		return pos

	_aim_deviation_time -= delta
	if _aim_deviation_time <= 0.0:
		var values := _combat_values()
		var max_angle := deg_to_rad(maxf(values.aim_deviation_degrees, 0.0))
		var radius := tan(max_angle) * distance
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf() * radius
		var right := actor.global_transform.basis.x.normalized()
		var up := Vector3.UP
		_aim_deviation = right * offset.x + up * offset.y * 0.1
		var refresh_min := maxf(values.aim_deviation_refresh_min, 0.0)
		var refresh_max := maxf(values.aim_deviation_refresh_max, refresh_min)
		_aim_deviation_time = randf_range(refresh_min, refresh_max)

	return pos + _aim_deviation

func _update_last_seen_position(delta: float) -> void:
	_target_position_refresh_time -= delta
	if _target_position_refresh_time > 0.0:
		return
	last_seen = _aim_position(target)
	_reset_target_position_refresh()

func _reset_target_position_refresh() -> void:
	var values := _combat_values()
	var refresh_min := maxf(values.target_position_refresh_min, 0.0)
	var refresh_max := maxf(values.target_position_refresh_max, refresh_min)
	_target_position_refresh_time = randf_range(refresh_min, refresh_max)

func _reset_aim_deviation() -> void:
	_aim_deviation_time = 0.0
	_aim_deviation = Vector3.ZERO

func _aim_position(enemy: Actor) -> Vector3:
	var estimated_enemy_position := _estimated_enemy_position(enemy)
	var fallback := _default_aim_position(enemy, estimated_enemy_position)
	return auto_behavior.selected_item_aim_position(enemy, fallback, estimated_enemy_position)

func _default_aim_position(enemy: Actor, estimated_enemy_position: Vector3) -> Vector3:
	var look_reference := enemy.get_look_reference()
	if look_reference:
		return estimated_enemy_position + look_reference.global_position - enemy.global_position
	return estimated_enemy_position

func _estimated_enemy_position(enemy: Actor) -> Vector3:
	var prediction_seconds := maxf(_combat_values().target_prediction_max_seconds, 0.0)
	if prediction_seconds > 0.1:
		prediction_seconds = max(randf() * prediction_seconds, 0.1)
	return enemy.global_position + enemy.velocity * prediction_seconds

func _nearest_health_pack() -> Node3D:
	var nearest: Node3D = null
	var best := INF
	for node in get_tree().get_nodes_in_group("health_packs"):
		var pack := node as Node3D
		if pack == null:
			continue
		var d := actor.global_position.distance_squared_to(pack.global_position)
		if d < best:
			best = d
			nearest = pack
	return nearest

func _combat_values() -> AutoBehaviorCombatValues:
	return auto_behavior.selected_item_combat_values()

func _rid(node: Node) -> RID:
	return node.get_rid() if node is CollisionObject3D else RID()
