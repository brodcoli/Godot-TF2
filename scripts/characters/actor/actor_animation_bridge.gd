extends Node
class_name ActorAnimationBridge

signal motion_updated(info: Dictionary)
signal action_sent(action: StringName, info: Dictionary, payload: Variant)

var actor: Actor
var _world_model: Node
var _view_model: Node

func _ready() -> void:
	actor = get_parent() as Actor
	if actor == null:
		return

	_connect_actor_signal(actor.inventory_changed, _on_inventory_changed)
	_connect_actor_signal(actor.selected_inventory_item_changed, _on_selected_inventory_item_changed)
	_connect_actor_signal(actor.inventory_item_use_attempted, _on_inventory_item_use_attempted)
	_connect_actor_signal(actor.inventory_item_used, _on_inventory_item_used)
	_connect_actor_signal(actor.damaged, _on_damaged)
	_connect_actor_signal(actor.killed, _on_killed)
	_connect_actor_signal(actor.entered_dead_state, _on_entered_dead_state)

func _process(_delta: float) -> void:
	if actor == null:
		return

	_setup_models_if_needed()
	var info := get_motion_info()
	_call_model_hook(&"actor_motion", [info])
	motion_updated.emit(info)

func get_motion_info() -> Dictionary:
	var horizontal_velocity := Vector3(actor.velocity.x, 0.0, actor.velocity.z)
	var local_velocity := actor.global_transform.basis.inverse() * actor.velocity
	var max_speed := _max_move_speed()
	var speed_ratio := clampf(horizontal_velocity.length() / max_speed, 0.0, 1.0)

	return {
		"velocity": actor.velocity,
		"local_velocity": local_velocity,
		"speed": horizontal_velocity.length(),
		"speed_ratio": speed_ratio,
		"idle_run": lerpf(-1.0, 1.0, speed_ratio),
		"move": Vector2(clampf(local_velocity.x / max_speed, -1.0, 1.0), clampf(-local_velocity.z / max_speed, -1.0, 1.0)),
		"look": Vector2(0.0, _look_pitch()),
		"move_input": actor.command.move_dir,
		"on_floor": actor.is_on_floor(),
		"in_water": not actor.water_bodies.is_empty(),
		"in_vehicle": actor.current_vehicle != null,
		"control_state": actor.control_state_machine.current_state_name() if actor.control_state_machine and actor.control_state_machine.current_state else "",
		"selected_item": actor.get_selected_inventory_item(),
	}

func send_action(action: StringName, payload: Variant = null) -> void:
	var info := get_motion_info()
	_call_model_hook(&"actor_action", [action, info, payload])
	action_sent.emit(action, info, payload)

func _setup_models_if_needed() -> void:
	if actor.world_model_instance != _world_model:
		_world_model = actor.world_model_instance
		_call_hook(_world_model, &"setup_actor_animation", [actor, self])

	if actor.view_model_instance != _view_model:
		_view_model = actor.view_model_instance
		_call_hook(_view_model, &"setup_actor_animation", [actor, self])

func _call_model_hook(method: StringName, args: Array) -> void:
	_call_hook(_world_model, method, args)
	_call_hook(_view_model, method, args)

func _call_hook(node: Node, method: StringName, args: Array) -> void:
	if node == null:
		return
	if node.has_method(method):
		node.callv(method, args)
	for child in node.get_children():
		_call_hook(child, method, args)

func _max_move_speed() -> float:
	var speed := 1.0
	var walking_state := actor.get_node_or_null("ControlStateMachine/Walking")
	if walking_state:
		var walking_speed = walking_state.get("MAX_MOVE_VELOCITY")
		if walking_speed != null:
			speed = float(walking_speed)
	if actor.character_definition:
		speed *= actor.character_definition.move_speed_multiplier
	return maxf(speed, 0.001)

func _look_pitch() -> float:
	if actor.head == null:
		return 0.0
	return clampf(-actor.head.rotation.x / deg_to_rad(89.0), -1.0, 1.0)

func _connect_actor_signal(actor_signal: Signal, callable: Callable) -> void:
	if not actor_signal.is_connected(callable):
		actor_signal.connect(callable)

func _on_inventory_changed() -> void:
	send_action(&"inventory_changed")

func _on_selected_inventory_item_changed() -> void:
	send_action(&"selected_item_changed", actor.get_selected_inventory_item())

func _on_inventory_item_use_attempted(item: Node3D, used_held: bool, succeeded: bool) -> void:
	send_action(&"item_use_attempted", {"item": item, "used_held": used_held, "succeeded": succeeded})

func _on_inventory_item_used() -> void:
	send_action(&"item_used", actor.get_selected_inventory_item())

func _on_damaged(amount: int, location: Vector3, attacker: Actor) -> void:
	send_action(&"damaged", {"amount": amount, "location": location, "attacker": attacker})

func _on_killed(attacker: Actor, victim: Actor) -> void:
	send_action(&"killed", {"attacker": attacker, "victim": victim})

func _on_entered_dead_state() -> void:
	send_action(&"entered_dead_state")
