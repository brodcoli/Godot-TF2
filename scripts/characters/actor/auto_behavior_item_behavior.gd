extends Node
class_name AutoBehaviorItemBehavior

@export var default_combat_values := AutoBehaviorCombatValues.new()

@export var item_entries: Array[AutoBehaviorItemEntry] = []

func combat_values(item: Node) -> AutoBehaviorCombatValues:
	var entry := _entry_for_item(item)
	if entry and entry.combat_values:
		return entry.combat_values
	return default_combat_values

func aim_position(item: Node, actor: Actor, enemy: Actor, fallback: Vector3, estimated_enemy_position: Vector3) -> Vector3:
	var values := combat_values(item)
	if values.use_launcher_ground_aim:
		return _launcher_aim_position(item, actor, enemy, fallback, estimated_enemy_position)
	return fallback

func resources_low(item: Node, threshold := 0.2) -> bool:
	if item == null or item.get("ammo") == null:
		return false

	var constants: Dictionary = item.get_script().get_script_constant_map()
	var max_ammo := float(constants.get("MAX_AMMO", item.get("ammo")))
	var total := float(item.get("ammo"))
	if item.get("clip") != null:
		max_ammo += float(constants.get("CLIP_SIZE", item.get("clip")))
		total += float(item.get("clip"))
	return max_ammo > 0.0 and total / max_ammo <= threshold

func _launcher_aim_position(item: Node, actor: Actor, enemy: Actor, fallback: Vector3, estimated_enemy_position: Vector3) -> Vector3:
	var from := estimated_enemy_position + Vector3.UP * 0.1
	var to := estimated_enemy_position + Vector3.DOWN * 2.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_rid(actor), _rid(enemy), _rid(item)]
	query.collide_with_bodies = true
	var hit := enemy.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.get("position") is Vector3:
		var hit_position: Vector3 = hit["position"]
		#if _is_obstructed_to_enemy(hit_position+Vector3.UP*0.02, item, actor, enemy):
			#return enemy.head.global_position + Vector3.DOWN*0.1
		return hit_position
	return fallback

func _is_obstructed_to_enemy(hit_position: Vector3, item: Node, actor: Actor, enemy: Actor) -> bool:
	var to := enemy.global_position
	var direction := to - hit_position
	if direction.length_squared() == 0.0:
		return false

	var query := PhysicsRayQueryParameters3D.create(hit_position + direction.normalized() * 0.05, to)
	query.exclude = [_rid(actor), _rid(enemy), _rid(item)]
	query.collide_with_bodies = true
	var hit := enemy.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func _entry_for_item(item: Node) -> AutoBehaviorItemEntry:
	var item_scene_path := _item_scene_path(item)
	if item_scene_path.is_empty():
		return null

	for entry in item_entries:
		if entry == null or entry.item_scene == null:
			continue
		if entry.item_scene.resource_path == item_scene_path:
			return entry
	return null

func _item_scene_path(item: Node) -> String:
	if item == null:
		return ""
	return item.scene_file_path

func _rid(node: Node) -> RID:
	return node.get_rid() if node is CollisionObject3D else RID()
