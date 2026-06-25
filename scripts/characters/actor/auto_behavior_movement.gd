extends Node
class_name AutoBehaviorMovement

const THREAT_LOOK_DOT := 0.45
const DEFAULT_MOVE_SPEED := 4.7
const UNREACHABLE_JUMP_INTERVAL := 0.45

@onready var auto_behavior: AutoBehavior = get_parent()
var actor: Actor = null
var agent: NavigationAgent3D = null

var _juke := Vector3.ZERO
var _juke_time := 0.0
var _unreachable_jump_time := 0.0

func tick(delta: float) -> void:
	if actor == null:
		actor = auto_behavior.actor
		agent = $"../../NavigationAgent3D"
		if agent and not agent.velocity_computed.is_connected(_on_agent_velocity_computed):
			agent.velocity_computed.connect(_on_agent_velocity_computed)
	if agent == null:
		return

	var target := _avoidance_goal(auto_behavior.get_move_goal(), auto_behavior.get_move_avoidance_radius())
	if _watched_by_visible_enemy():
		_juke_time -= delta
		if _juke_time <= 0.0:
			_juke_time = randf_range(0.35, 0.9)
			_juke = _nav_point(actor.global_position + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))) - actor.global_position
		target += _juke * 0.4

	agent.target_position = _nav_point(target)
	var next := agent.get_next_path_position()
	if not agent.is_target_reachable():
		next = target
		_unreachable_jump_time -= delta
		if _unreachable_jump_time <= 0.0:
			_unreachable_jump_time = UNREACHABLE_JUMP_INTERVAL
			actor.command.press_jump_once()
	else:
		_unreachable_jump_time = 0.0

	var dir := next - actor.global_position
	dir.y = 0.0
	var desired_velocity := Vector3.ZERO if dir.length_squared() < 0.04 else dir.normalized() * _agent_move_speed()
	if agent.avoidance_enabled:
		agent.set_velocity(desired_velocity)
	else:
		_apply_move_velocity(desired_velocity)

func _on_agent_velocity_computed(safe_velocity: Vector3) -> void:
	_apply_move_velocity(safe_velocity)

func _apply_move_velocity(move_velocity: Vector3) -> void:
	move_velocity.y = 0.0
	actor.command.move_dir = Vector2.ZERO if move_velocity.length_squared() < 0.04 else _world_to_input(move_velocity.normalized())

func _agent_move_speed() -> float:
	return agent.max_speed if agent and agent.max_speed > 0.0 else DEFAULT_MOVE_SPEED

func _avoidance_goal(goal: Vector3, radius: float) -> Vector3:
	if radius <= 0.0:
		return goal
	var from_goal := actor.global_position - goal
	from_goal.y = 0.0
	if from_goal.length_squared() == 0.0:
		from_goal = actor.global_transform.basis.z
	return goal + from_goal.normalized() * radius

func _world_to_input(dir: Vector3) -> Vector2:
	var local := actor.global_transform.basis.inverse() * dir
	return Vector2(local.x, local.z).limit_length(1.0)

func _watched_by_visible_enemy() -> bool:
	for node in get_tree().get_nodes_in_group("actors"):
		var enemy := node as Actor
		if enemy and auto_behavior.combat.is_enemy(enemy) and auto_behavior.combat.can_see(enemy):
			var enemy_forward := -enemy.get_look_reference().global_transform.basis.z
			var to_self := (actor.global_position - enemy.global_position).normalized()
			if enemy_forward.dot(to_self) > THREAT_LOOK_DOT:
				return true
	return false

func _nav_point(pos: Vector3) -> Vector3:
	var map := actor.get_world_3d().navigation_map
	return NavigationServer3D.map_get_closest_point(map, pos) if map.is_valid() else pos
