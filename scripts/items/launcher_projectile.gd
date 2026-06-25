extends CharacterBody3D
class_name LauncherProjectile

const GLOBAL_MAX_EXPLOSION_LIGHTS := 2
const FULL_PUSH_DISTANCE := 2.5
const HAMMER_UNITS_PER_METER := 39.3701
const DAMAGE_NEUTRAL_DISTANCE_HU := 512.0
const DAMAGE_FALLOFF_CAP_DISTANCE_HU := 921.6
const DAMAGE_MIN_DISTANCE_MODIFIER := 0.528
const SELF_AIRBORNE_DAMAGE_MODIFIER := 0.6

static var active_explosion_lights: Array[LauncherProjectile] = []

@export var speed := 35.0
@export var explosion_radius := 146.0 / HAMMER_UNITS_PER_METER
@export var explosion_max_damage := 90
@export var explosion_max_push_velocity := 12.5

var _direction := Vector3.FORWARD
var _explosion_path_exclusions: Array[RID] = []
var _source_actor: Actor = null

var already_exploded = false

func setup(start_position: Vector3, target_position: Vector3, exclude_nodes: Array[Node] = []) -> void:
	global_position = start_position
	_source_actor = exclude_nodes[0] as Actor if not exclude_nodes.is_empty() else null

	var launch_direction := target_position - start_position
	if launch_direction.length_squared() == 0.0:
		launch_direction = -global_transform.basis.z
	_direction = launch_direction.normalized()
	look_at(global_position + _direction)

	for node in exclude_nodes:
		if node is CollisionObject3D:
			add_collision_exception_with(node)
		_add_collision_exclusions(_explosion_path_exclusions, node)

	$ExplosionLight.visible = false

func _physics_process(delta: float) -> void:
	var dist_from_cam = (global_position - get_viewport().get_camera_3d().global_position).length()

	var collision := move_and_collide(_direction * speed * delta)
	if collision and not already_exploded:
		_explode(collision)
		$TrailParticles.visible = false
		$MeshInstance3D.visible = false

		if dist_from_cam < 25:
			active_explosion_lights.append(self)
			$ExplosionLight/AnimationPlayer.play("explode")
			_update_explosion_lights()

		$ExplosionParticles.amount = 3
		if dist_from_cam > 10:
			$ExplosionParticles.amount = 2
		elif dist_from_cam > 40:
			$ExplosionParticles.amount = 1

		if dist_from_cam < 100:
			$ExplosionParticles.restart()
			await $ExplosionParticles.finished
		queue_free()
	elif dist_from_cam > 1000:
		queue_free()

	if not already_exploded:
		if dist_from_cam < 5:
			$TrailParticles.amount = 3
			$TrailParticles.visible = true
		elif dist_from_cam < 12:
			$TrailParticles.amount = 2
			$TrailParticles.visible = true
		elif dist_from_cam < 50:
			$TrailParticles.amount = 1
			$TrailParticles.visible = true
		else:
			$TrailParticles.visible = false

func _exit_tree() -> void:
	active_explosion_lights.erase(self)
	_update_explosion_lights()

func _explode(collision: KinematicCollision3D) -> void:
	already_exploded = true

	if explosion_radius <= 0.0:
		return

	var explosion_center := collision.get_position() + collision.get_normal() * 0.05
	var space_state := get_world_3d().direct_space_state

	var affected_nodes: Array[Node] = []
	for target in _find_hurt_targets(get_tree().current_scene):

		if affected_nodes.has(target):
			continue

		var target_distance_position := target.global_position
		var target_direction_position := _get_direction_position(target)
		var distance := explosion_center.distance_to(target_distance_position)
		if distance > explosion_radius:
			continue

		if not _has_clear_explosion_path(space_state, explosion_center, target_direction_position, target):
			continue

		var direct_hit := _is_direct_hit(collision, target)
		var push_falloff_distance = max(explosion_radius - FULL_PUSH_DISTANCE, 0.001)
		var push_falloff := clampf((explosion_radius - distance) / push_falloff_distance, 0.0, 1.0)
		_push_actor_from_explosion(target, explosion_center, target_direction_position, push_falloff)

		if explosion_max_damage > 0:
			var damage := _calculate_damage(target, distance, direct_hit)
			if damage > 0:
				target.hurt(damage, _source_actor, target_direction_position)

		affected_nodes.append(target)

func _calculate_damage(target: Node3D, explosion_distance: float, direct_hit: bool) -> int:
	var damage := float(explosion_max_damage)
	var splash_modifier := 1.0 if direct_hit else _calculate_splash_modifier(explosion_distance)

	damage *= splash_modifier
	if target == _source_actor:
		if target is Actor and not (target as Actor).is_on_floor():
			damage *= SELF_AIRBORNE_DAMAGE_MODIFIER
	else:
		damage *= _calculate_enemy_distance_modifier(target)

	return roundi(damage)

func _calculate_splash_modifier(explosion_distance: float) -> float:
	if explosion_radius <= 0.0:
		return 0.0

	return clampf(1.0 - explosion_distance / (2.0 * explosion_radius), 0.5, 1.0)

func _calculate_enemy_distance_modifier(target: Node3D) -> float:
	if _source_actor == null:
		return 1.0

	var distance_hu := _source_actor.global_position.distance_to(target.global_position) * HAMMER_UNITS_PER_METER
	if distance_hu <= DAMAGE_NEUTRAL_DISTANCE_HU:
		return lerpf(1.25, 1.0, distance_hu / DAMAGE_NEUTRAL_DISTANCE_HU)

	var falloff_range := DAMAGE_FALLOFF_CAP_DISTANCE_HU - DAMAGE_NEUTRAL_DISTANCE_HU
	var falloff_t := clampf((distance_hu - DAMAGE_NEUTRAL_DISTANCE_HU) / falloff_range, 0.0, 1.0)
	return lerpf(1.0, DAMAGE_MIN_DISTANCE_MODIFIER, falloff_t)

func _is_direct_hit(collision: KinematicCollision3D, target: Node3D) -> bool:
	var collider := collision.get_collider() as Node
	return collider == target or (collider != null and target.is_ancestor_of(collider))

func _push_actor_from_explosion(target: Node3D, explosion_center: Vector3, target_position: Vector3, falloff: float) -> void:
	if explosion_max_push_velocity <= 0.0 or not target is Actor:
		return

	var actor := target as Actor
	if _source_actor != null and actor != _source_actor and actor.team == _source_actor.team:
		return

	var push_direction := target_position - explosion_center
	if push_direction.length_squared() == 0.0:
		push_direction = Vector3.UP
	else:
		push_direction = push_direction.normalized()

	actor.velocity += push_direction * explosion_max_push_velocity * falloff

func _find_hurt_targets(root: Node) -> Array[Node3D]:
	var targets: Array[Node3D] = []
	if root == null:
		return targets

	_collect_hurt_targets(root, targets)
	return targets

func _collect_hurt_targets(node: Node, targets: Array[Node3D]) -> void:
	if node is Node3D and node.has_method("hurt"):
		targets.append(node)

	for child in node.get_children():
		_collect_hurt_targets(child, targets)

func _get_direction_position(target: Node3D) -> Vector3:
	var head := target.get_node_or_null("Head") as Node3D
	if head:
		return head.global_position

	return target.global_position

func _has_clear_explosion_path(space_state: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, target: Node3D) -> bool:
	var direction := to - from
	if direction.length_squared() == 0.0:
		return true

	var ray_from := from + direction.normalized() * 0.05
	var exclusions: Array[RID] = [get_rid()]
	for rid in _explosion_path_exclusions:
		if not exclusions.has(rid):
			exclusions.append(rid)

	var ray_query := PhysicsRayQueryParameters3D.create(ray_from, to)
	ray_query.exclude = exclusions
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = true

	var hit := space_state.intersect_ray(ray_query)
	if hit.is_empty():
		return true

	var collider := hit.get("collider") as Node
	return collider == target or (collider != null and target.is_ancestor_of(collider))

func _add_collision_exclusions(exclusions: Array[RID], node: Node) -> void:
	if node is CollisionObject3D:
		var rid = node.get_rid()
		if not exclusions.has(rid):
			exclusions.append(rid)

	for child in node.get_children():
		_add_collision_exclusions(exclusions, child)

static func _update_explosion_lights() -> void:
	active_explosion_lights = active_explosion_lights.filter(func(p): return is_instance_valid(p))
	if active_explosion_lights.is_empty():
		return

	var camera := active_explosion_lights[0].get_viewport().get_camera_3d()
	active_explosion_lights.sort_custom(func(a, b): return a.global_position.distance_squared_to(camera.global_position) < b.global_position.distance_squared_to(camera.global_position))

	for i in active_explosion_lights.size():
		var light := active_explosion_lights[i].get_node("ExplosionLight")
		light.visible = i < GLOBAL_MAX_EXPLOSION_LIGHTS
