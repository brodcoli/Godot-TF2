extends Node
class_name ActorPlayerControl

const DEBUG_PLAYER_INFINITE_HEALTH = false

var is_player_controlled := false:
	set(value):
		if is_player_controlled == value:
			return
		if value and is_inside_tree():
			_release_other_player_control()
		is_player_controlled = value
		if is_inside_tree():
			_apply_player_controlled()

var disable_movement_input := false
var touch_control_move_dir := Vector2.ZERO
var touch_control_look_dir := Vector2.ZERO

@onready var actor: Actor = get_parent() as Actor

var _restore_auto_behavior := false
var _last_health_ratio := 1.0
var _damage_health_fill_time := 0.0

func _ready() -> void:
	if actor:
		await actor.ready
	_apply_player_controlled()

func _process(_delta: float) -> void:
	if actor == null or not is_player_controlled:
		return

	if DEBUG_PLAYER_INFINITE_HEALTH:
		actor.health = actor.max_health

	_damage_health_fill_time = maxf(_damage_health_fill_time - _delta, 0.0)
	if _damage_health_fill_time <= 0.0:
		var damage_health_fill := actor.get_node_or_null("PlayerUI/HUD/Health/HealthBG/MarginContainer/DamageHealthFill") as ColorRect
		var health_fill := actor.get_node_or_null("PlayerUI/HUD/Health/HealthBG/MarginContainer/HealthFill") as ColorRect
		if damage_health_fill and health_fill:
			damage_health_fill.scale.x = health_fill.scale.x

	if actor.command.inputs_disabled:
		touch_control_move_dir = Vector2.ZERO
		_update_look_command()
		_update_camera_fov()
		return

	_update_command()
	_update_camera_fov()

	if Input.is_action_just_pressed("toggle_cam"):
		toggle_camera()

	if actor.command.is_use_just_pressed():
		if actor.use_selected_inventory_item():
			return

		if actor.look_ray and actor.look_ray.is_colliding():
			var collider = actor.look_ray.get_collider()
			if collider is Interactable:
				collider.interact(actor)

	if actor.command.use_held:
		actor.use_held_selected_inventory_item()

func _input(event: InputEvent) -> void:
	if actor == null or not is_player_controlled:
		return

	if not actor.command.inputs_disabled and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			actor.select_adjacent_inventory_item(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			actor.select_adjacent_inventory_item(1)

	var mouse_sens = Settings.mouse_sensitivity / 16500.0
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		actor.command.look_delta += event.screen_relative * mouse_sens

func make_player_controlled() -> void:
	is_player_controlled = true

func toggle_camera() -> void:
	if actor == null or actor.cam_first == null or actor.cam_third == null:
		return

	if actor.cam_first.current:
		actor.cam_first.current = false
		actor.cam_third.current = true
	else:
		actor.cam_first.current = true
		actor.cam_third.current = false
	actor.refresh_held_inventory_item_parent()

func _release_other_player_control() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var other_actor := node as Actor
		if other_actor == null or other_actor == actor:
			continue
		var other_control := other_actor.get_node_or_null("PlayerControl") as ActorPlayerControl
		if other_control:
			other_control.is_player_controlled = false

func _apply_player_controlled() -> void:
	if actor == null:
		return

	if is_player_controlled:
		actor.add_to_group("player")
		actor.set_view_model_visible(true)
		actor.set_first_person_world_model_hidden(true)
		Input.use_accumulated_input = false
		if actor.cam_first and not actor.cam_first.current and (actor.cam_third == null or not actor.cam_third.current):
			actor.cam_first.current = true
		actor.refresh_held_inventory_item_parent()
		if actor.auto_behavior and actor.auto_behavior.enabled:
			_restore_auto_behavior = true
			actor.auto_behavior.enabled = false
		if not actor.health_changed.is_connected(_on_health_changed):
			actor.health_changed.connect(_on_health_changed)
		_set_player_nodes_visible(true)
		_update_health_ui()
	else:
		actor.remove_from_group("player")
		actor.set_view_model_visible(false)
		actor.set_first_person_world_model_hidden(false)
		_clear_command()
		if actor.cam_first:
			actor.cam_first.current = false
		if actor.cam_third:
			actor.cam_third.current = false
		actor.refresh_held_inventory_item_parent()
		if _restore_auto_behavior and actor.auto_behavior:
			actor.auto_behavior.enabled = true
		_restore_auto_behavior = false
		if actor.health_changed.is_connected(_on_health_changed):
			actor.health_changed.disconnect(_on_health_changed)
		_set_player_nodes_visible(false)

func _set_player_nodes_visible(is_visible: bool) -> void:
	var player_ui := actor.get_node_or_null("PlayerUI")
	if player_ui:
		for child in player_ui.get_children():
			_set_visible_player_ui_node(child, is_visible)

func _set_visible_player_ui_node(node: Node, is_visible: bool) -> void:
	if node.has_method("set_player_ui_visible"):
		node.set_player_ui_visible(is_visible)
		return

	if node is CanvasLayer:
		node.visible = is_visible
		return
	if node is CanvasItem:
		node.visible = is_visible
		return

	for child in node.get_children():
		_set_visible_player_ui_node(child, is_visible)

func _clear_command() -> void:
	touch_control_move_dir = Vector2.ZERO
	touch_control_look_dir = Vector2.ZERO
	actor.command.move_dir = Vector2.ZERO
	actor.command.look_delta = Vector2.ZERO
	actor.command.jump_pressed = false
	actor.command.jump_held = false
	actor.command.use_pressed = false
	actor.command.use_held = false
	actor.command.exit_vehicle_pressed = false
	actor.command.inputs_disabled = false
	actor.command.movement_disabled = false

func _update_command() -> void:
	if actor.command.inputs_disabled:
		touch_control_move_dir = Vector2.ZERO
		_update_look_command()
		return

	actor.command.move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	actor.command.move_dir += touch_control_move_dir
	_update_look_command()
	actor.command.jump_pressed = Input.is_action_just_pressed("jump")
	actor.command.jump_held = Input.is_action_pressed("jump")
	actor.command.use_pressed = Input.is_action_just_pressed("use")
	actor.command.use_held = Input.is_action_pressed("use")
	actor.command.exit_vehicle_pressed = Input.is_action_just_pressed("exit_vehicle")
	actor.command.movement_disabled = disable_movement_input

func _update_look_command() -> void:
	actor.command.look_delta += touch_control_look_dir * (Settings.mouse_sensitivity / 16500.0)
	touch_control_look_dir = Vector2.ZERO

func _update_camera_fov() -> void:
	if actor.cam_first and actor.cam_first.fov != Settings.camera_fov:
		actor.cam_first.fov = Settings.camera_fov
	if actor.cam_third and actor.cam_third.fov != Settings.camera_fov:
		actor.cam_third.fov = Settings.camera_fov

func _on_health_changed(_health: int, _max_health: int) -> void:
	_update_health_ui()

func _update_health_ui() -> void:
	var health_fill := actor.get_node_or_null("PlayerUI/HUD/Health/HealthBG/MarginContainer/HealthFill") as ColorRect
	var damage_health_fill := $"../PlayerUI/HUD/Health/HealthBG/MarginContainer/DamageHealthFill" as ColorRect
	var damage_health_fill_anim: AnimationPlayer = $"../PlayerUI/HUD/Health/HealthBG/MarginContainer/DamageHealthFill/AnimationPlayer"
	var health_label := actor.get_node_or_null("PlayerUI/HUD/Health/HealthBG/MarginContainer2/HealthLabel") as Label
	if health_fill == null or health_label == null:
		return

	var health_ratio := clampf(float(actor.health) / float(actor.max_health), 0.0, 1.0)
	health_fill.size_flags_horizontal = Control.SIZE_FILL
	health_fill.custom_minimum_size.x = 0.0
	health_fill.scale.x = health_ratio
	
	if damage_health_fill:
		damage_health_fill.size_flags_horizontal = Control.SIZE_FILL
		damage_health_fill.custom_minimum_size.x = 0.0
		if health_ratio < _last_health_ratio:
			damage_health_fill.scale.x = _last_health_ratio
			_damage_health_fill_time = 1.0
			damage_health_fill_anim.stop()
			damage_health_fill_anim.play("fade")
		elif _damage_health_fill_time <= 0.0:
			damage_health_fill.scale.x = health_ratio
			
	health_label.text = str(actor.health)
	var shader_material := health_label.material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("label_width", health_label.size.x)
		shader_material.set_shader_parameter("ratio", health_ratio)
	_last_health_ratio = health_ratio
