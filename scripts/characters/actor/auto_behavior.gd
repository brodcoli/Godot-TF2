extends Node
class_name AutoBehavior

@export var enabled := false
@export var goal_position := Vector3.ZERO
@export var goal_radius := 0.0
@export var goal_avoidance_radius := 0.0

@onready var actor: Actor = get_parent()
@onready var movement: AutoBehaviorMovement = $Movement
@onready var combat: AutoBehaviorCombat = $Combat
@onready var item_behavior: AutoBehaviorItemBehavior = $ItemBehavior

var _real_goal := Vector3.ZERO
var _last_goal := Vector3.INF
var _last_radius := -1.0

func _ready() -> void:
	_apply_default_goal_for_current_map()
	_pick_goal()

func _process(delta: float) -> void:
	if not enabled:
		return

	if actor.health <= 0:
		actor.command.clear_input_values()
		return

	if goal_position != _last_goal or goal_radius != _last_radius:
		_pick_goal()

	combat.tick(delta)
	movement.tick(delta)
	_process_item_use()

func set_goal(pos: Vector3, random_radius := 0.0, avoidance_radius := 0.0) -> void:
	goal_position = pos
	goal_radius = random_radius
	goal_avoidance_radius = avoidance_radius
	_pick_goal()

func get_move_goal() -> Vector3:
	return combat.move_goal if combat.has_move_goal else _real_goal

func get_move_avoidance_radius() -> float:
	return combat.move_avoidance_radius if combat.has_move_goal else goal_avoidance_radius

func report_attacked_by(enemy: Actor) -> void:
	combat.engage(enemy)

func _process_item_use() -> void:
	if actor.command.is_use_just_pressed():
		actor.use_selected_inventory_item()
	if actor.command.use_held:
		actor.use_held_selected_inventory_item()

func selected_item_combat_values() -> AutoBehaviorCombatValues:
	var item := actor.get_selected_inventory_item()
	return item_behavior.combat_values(item)

func selected_item_aim_position(enemy: Actor, fallback: Vector3, estimated_enemy_position: Vector3) -> Vector3:
	return item_behavior.aim_position(actor.get_selected_inventory_item(), actor, enemy, fallback, estimated_enemy_position)

func selected_item_resources_low(threshold := 0.1) -> bool:
	return item_behavior.resources_low(actor.get_selected_inventory_item(), threshold)

func _pick_goal() -> void:
	_last_goal = goal_position
	_last_radius = goal_radius
	var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf() * maxf(goal_radius, 0.0)
	_real_goal = goal_position + Vector3(offset.x, 0.0, offset.y)

func _apply_default_goal_for_current_map() -> void:
	var map := _get_current_map()
	if map is MapKOTH and map.control_point:
		set_goal(map.control_point.global_position, 3.0, 0.0)

func _get_current_map() -> Node:
	var node := actor.get_parent()
	while node:
		if node is MapKOTH:
			return node
		node = node.get_parent()
	return null
