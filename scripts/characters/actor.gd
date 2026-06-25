@tool
extends CharacterBody3D
class_name Actor

signal entered_water
signal exited_water
signal head_entered_water
signal head_exited_water
signal entered_dead_state
signal killed(attacker: Actor, victim: Actor)
signal damaged(amount: int, location: Vector3, attacker: Actor)
signal health_changed(health: int, max_health: int)
signal inventory_changed
signal selected_inventory_item_changed
signal inventory_item_use_attempted(item: Node3D, used_held: bool, succeeded: bool)
signal inventory_item_used

const VIEW_MODEL_LAYER := 2
const WORLD_MODEL_LAYER := 1
const FIRST_PERSON_HIDDEN_WORLD_MODEL_LAYER := 3
const DEBUG_ALL_VISUAL_LAYERS := (1 << 20) - 1

@onready var head: Node3D = get_node_or_null("Head")
@onready var head_area: Area3D = get_node_or_null("Head/HeadArea")
@onready var cam_first: Camera3D = %CamFirst
@onready var cam_third: Camera3D = %CamThird
@onready var look_ray: RayCast3D = get_node_or_null("Head/LookRay")
@onready var control_state_machine: StateMachine = get_node_or_null("ControlStateMachine")
@onready var world_model_root: Node3D = get_node_or_null("WorldModelRoot")
@onready var default_world_model: Node3D = get_node_or_null("WorldModelRoot/DefaultWorldModel")
@onready var view_model_root: Node3D = get_node_or_null("Head/CamFirst/ViewModelRoot")
@onready var inventory_storage_root: Node3D = get_node_or_null("InventoryStorageRoot")
@onready var inventory_hold_point: Node3D = %InventoryHoldPoint

@onready var _damage_indicator_ui: DamageIndicatorUI = $PlayerUI/DamageIndicatorUI

@onready var auto_behavior: AutoBehavior = $AutoBehavior

@export var is_player_controlled := false:
	set(value):
		is_player_controlled = value
		$PlayerControl.is_player_controlled = value

@export var character_definition: CharacterDefinition:
	set(value):
		if character_definition and character_definition.changed.is_connected(_on_character_definition_changed):
			character_definition.changed.disconnect(_on_character_definition_changed)

		character_definition = value

		if character_definition and not character_definition.changed.is_connected(_on_character_definition_changed):
			character_definition.changed.connect(_on_character_definition_changed)

		if Engine.is_editor_hint() and is_inside_tree():
			_setup_editor_world_model()

@export var debug_view_model_visible_from_any_camera := false:
	set(value):
		debug_view_model_visible_from_any_camera = value
		_apply_view_model_visual_layers()

@export var initial_selected_inventory_index := 0
@export var username := "Actor"
@export var max_health := 100:
	set(value):
		var new_max_health := maxi(value, 1)
		if max_health == new_max_health:
			return

		max_health = new_max_health
		var old_health := health
		health = clampi(health, 0, max_health)
		if health == old_health:
			health_changed.emit(health, max_health)

@export var health := 100:
	set(value):
		var new_health := clampi(value, 0, max_health)
		if health == new_health:
			return

		health = new_health
		health_changed.emit(health, max_health)
		if health <= 0:
			control_state_machine.change_state("dead")

@export var world_model_visual_layer := WORLD_MODEL_LAYER:
	set(value):
		world_model_visual_layer = clampi(value, 1, 20)
		if world_model_instance:
			_apply_world_model_visual_layers()

@export var team: Team = TeamManager.teams[TeamManager.TeamID.UNASSIGNED]:
	set(value):
		if team == value:
			return

		team = value
		if is_inside_tree() and character_definition:
			_setup_character_visuals()
var capture_value := 1

@export var enable_auto_behavior_on_ready := false

var command := ActorCommand.new()
var water_bodies: Array = []
var head_water_bodies: Array = []
var current_vehicle: Vehicle = null
var world_model_instance: Node
var view_model_instance: Node
var inventory: Array[Node3D] = []
var selected_inventory_index := -1
var _hide_world_model_from_first_person := false

func _ready() -> void:
	if character_definition and not character_definition.changed.is_connected(_on_character_definition_changed):
		character_definition.changed.connect(_on_character_definition_changed)

	if Engine.is_editor_hint():
		_setup_editor_world_model()
		return

	add_to_group("actors")

	if character_definition:
		setup_character(character_definition)
	else:
		_set_default_world_model_visible(true)
		_setup_starting_inventory()

	if head_area:
		head_area.area_entered.connect(_on_head_area_entered)
		head_area.area_exited.connect(_on_head_area_exited)

	var water_areas = get_tree().get_nodes_in_group("water_body")
	for area in water_areas:
		if area is Area3D:
			area.body_entered.connect(_on_water_body_entered.bind(area))
			area.body_exited.connect(_on_water_body_exited.bind(area))

	if enable_auto_behavior_on_ready:
		auto_behavior.enabled = true

func consume_look_delta() -> Vector2:
	var value := command.look_delta
	command.look_delta = Vector2.ZERO
	return value

func enter_vehicle(vehicle: Vehicle) -> void:
	current_vehicle = vehicle
	vehicle.possess_vehicle(self)
	if control_state_machine:
		control_state_machine.change_state("driving")

func exit_vehicle() -> void:
	if current_vehicle:
		global_position = current_vehicle.get_best_exit_point(self)
		current_vehicle.unpossess_vehicle()
		current_vehicle = null
		if control_state_machine:
			control_state_machine.change_state("walking")

func add_inventory_item(item: Node3D, select_item := false) -> void:
	if item == null or inventory.has(item):
		return

	inventory.append(item)
	_parent_item_for_storage(item)
	item.visible = false
	_call_inventory_item_hook(item, "entered_inventory")

	if select_item or selected_inventory_index == -1:
		select_inventory_item(inventory.size() - 1)

	inventory_changed.emit()

func remove_inventory_item(item: Node3D) -> void:
	var index := inventory.find(item)
	if index == -1:
		return

	var was_selected := index == selected_inventory_index
	if was_selected:
		_unhold_inventory_item(item)

	inventory.remove_at(index)
	_call_inventory_item_hook(item, "left_inventory")
	item.visible = true

	if item.get_parent() == inventory_storage_root or item.get_parent() == inventory_hold_point:
		item.get_parent().remove_child(item)

	if inventory.is_empty():
		selected_inventory_index = -1
		selected_inventory_item_changed.emit()
	elif was_selected:
		select_inventory_item(clamp(index, 0, inventory.size() - 1))
	elif index < selected_inventory_index:
		selected_inventory_index -= 1
		selected_inventory_item_changed.emit()

	inventory_changed.emit()

func select_inventory_item(index: int) -> void:
	if index < 0 or index >= inventory.size():
		clear_selected_inventory_item()
		return

	if selected_inventory_index == index:
		return

	if selected_inventory_index >= 0 and selected_inventory_index < inventory.size():
		_unhold_inventory_item(inventory[selected_inventory_index])

	selected_inventory_index = index
	_hold_inventory_item(inventory[selected_inventory_index])
	selected_inventory_item_changed.emit()

func select_inventory_item_node(item: Node3D) -> void:
	select_inventory_item(inventory.find(item))

func select_adjacent_inventory_item(direction: int) -> void:
	if inventory.is_empty() or direction == 0:
		return

	var current_index := selected_inventory_index
	if current_index < 0 or current_index >= inventory.size():
		current_index = 0 if direction > 0 else inventory.size() - 1
	else:
		current_index = wrapi(current_index + direction, 0, inventory.size())

	select_inventory_item(current_index)

func clear_selected_inventory_item() -> void:
	if selected_inventory_index >= 0 and selected_inventory_index < inventory.size():
		_unhold_inventory_item(inventory[selected_inventory_index])
	selected_inventory_index = -1
	selected_inventory_item_changed.emit()

func get_selected_inventory_item() -> Node3D:
	if selected_inventory_index < 0 or selected_inventory_index >= inventory.size():
		return null
	return inventory[selected_inventory_index]

func use_selected_inventory_item() -> bool:
	var item := get_selected_inventory_item()
	if item == null:
		return false

	_call_inventory_item_hook(item, "used")
	var succeeded := _inventory_item_use_succeeded(item)
	inventory_item_use_attempted.emit(item, false, succeeded)
	if succeeded:
		inventory_item_used.emit()
	return true

func use_held_selected_inventory_item() -> bool:
	var item := get_selected_inventory_item()
	if item == null:
		return false

	_call_inventory_item_hook(item, "used_held")
	var succeeded := _inventory_item_use_succeeded(item)
	inventory_item_use_attempted.emit(item, true, succeeded)
	if succeeded:
		inventory_item_used.emit()
	return true

func _inventory_item_use_succeeded(item: Node3D) -> bool:
	if "last_use_succeeded" in item:
		return item.last_use_succeeded
	return true

func refill_inventory_items() -> void:
	for item in inventory:
		_refill_inventory_item(item)

func _refill_inventory_item(item: Node3D) -> void:
	if item == null:
		return

	if "clip" in item and "CLIP_SIZE" in item:
		item.clip = item.CLIP_SIZE
	if "ammo" in item and "MAX_AMMO" in item:
		item.ammo = item.MAX_AMMO

func hurt(amount: int, attacker: Actor = null, damage_location := Vector3.INF) -> void:
	if amount <= 0:
		return

	if attacker != null and attacker != self and attacker.team == team:
		return

	var old_health := health
	var was_alive := health > 0
	health -= amount
	var applied_damage := old_health - health
	if applied_damage > 0:
		var resolved_location := damage_location
		if not resolved_location.is_finite():
			resolved_location = global_position + Vector3.UP
		damaged.emit(applied_damage, resolved_location, attacker)
		if attacker != null:
			attacker.on_damage_dealth(applied_damage, resolved_location, self)
	if was_alive and health <= 0:
		killed.emit(attacker, self)
		if is_inside_tree():
			get_tree().call_group("kill_feed_listeners", "_on_actor_killed", attacker, self)
	if attacker and auto_behavior:
		auto_behavior.report_attacked_by(attacker)

func on_damage_dealth(amount: int, location: Vector3, victim: Actor) -> void:
	if victim != self:
		_damage_indicator_ui.show_damage_indicator(amount, location)

func heal(amount: int) -> void:
	if amount <= 0:
		return

	health += amount

func respawn_at(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	health = max_health
	refill_inventory_items()
	command.inputs_disabled = false
	command.movement_disabled = false
	if control_state_machine:
		control_state_machine.change_state("walking")

func _setup_starting_inventory() -> void:
	var starting_items: Array[Node3D] = []

	if inventory_storage_root:
		for child in inventory_storage_root.get_children():
			if child is Node3D:
				starting_items.append(child)

	if character_definition:
		for item_scene in character_definition.starting_inventory:
			if item_scene == null:
				continue

			var item := item_scene.instantiate()
			if item is Node3D:
				starting_items.append(item)
			else:
				if item is Node:
					item.queue_free()
				push_warning("CharacterDefinition starting inventory item must instantiate a Node3D.")

	for item in starting_items:
		add_inventory_item(item)

	if not inventory.is_empty():
		select_inventory_item(clamp(initial_selected_inventory_index, 0, inventory.size() - 1))

func get_look_reference() -> Node3D:
	return head if head else self

func setup_character(definition: CharacterDefinition) -> void:
	character_definition = definition
	max_health = character_definition.max_health
	health = max_health
	_setup_character_visuals()

	if not Engine.is_editor_hint():
		_setup_starting_inventory()

func _setup_character_visuals() -> void:
	_clear_character_nodes()

	var visual_override := character_definition.get_team_visual_override(team) if character_definition else null
	var world_model_scene := character_definition.world_model_scene
	var view_model_scene := character_definition.view_model_scene
	if visual_override:
		if visual_override.world_model_scene:
			world_model_scene = visual_override.world_model_scene
		if visual_override.view_model_scene:
			view_model_scene = visual_override.view_model_scene

	_set_default_world_model_visible(world_model_scene == null)

	if world_model_scene and world_model_root:
		world_model_instance = world_model_scene.instantiate()
		world_model_root.add_child(world_model_instance)
		_apply_model_offsets(
			world_model_instance,
			character_definition.world_model_position_offset,
			character_definition.world_model_rotation_offset_degrees
		)
		if visual_override:
			_apply_material_overrides(world_model_instance, visual_override.world_model_materials)
		_apply_world_model_visual_layers()

	if view_model_scene and view_model_root:
		view_model_instance = view_model_scene.instantiate()
		view_model_root.add_child(view_model_instance)
		_apply_model_offsets(
			view_model_instance,
			character_definition.view_model_position_offset,
			character_definition.view_model_rotation_offset_degrees
		)
		if visual_override:
			_apply_material_overrides(view_model_instance, visual_override.view_model_materials)
		_apply_view_model_visual_layers()

func set_first_person_world_model_hidden(is_hidden: bool) -> void:
	if _hide_world_model_from_first_person == is_hidden:
		return

	_hide_world_model_from_first_person = is_hidden
	_apply_world_model_visual_layers()
	_apply_default_world_model_visual_layers()

func _clear_character_nodes() -> void:
	for node in [world_model_instance, view_model_instance]:
		if node and is_instance_valid(node):
			if Engine.is_editor_hint():
				node.free()
			else:
				node.queue_free()

	world_model_instance = null
	view_model_instance = null

func _set_visual_layer(node: Node, layer: int) -> void:
	if node is VisualInstance3D:
		node.layers = 1 << (layer - 1)

	for child in node.get_children():
		_set_visual_layer(child, layer)

func _set_visual_layers(node: Node, layers: int) -> void:
	if node is VisualInstance3D:
		node.layers = layers

	for child in node.get_children():
		_set_visual_layers(child, layers)

func _apply_view_model_visual_layers() -> void:
	if not view_model_instance:
		return

	if debug_view_model_visible_from_any_camera:
		_set_visual_layers(view_model_instance, DEBUG_ALL_VISUAL_LAYERS)
	else:
		_set_visual_layer(view_model_instance, VIEW_MODEL_LAYER)

func set_view_model_visible(is_visible: bool) -> void:
	if view_model_instance:
		view_model_instance.visible = is_visible

func _apply_world_model_visual_layers() -> void:
	if not world_model_instance:
		return

	var layer := FIRST_PERSON_HIDDEN_WORLD_MODEL_LAYER if _hide_world_model_from_first_person else world_model_visual_layer
	_set_visual_layer(world_model_instance, layer)

func _apply_default_world_model_visual_layers() -> void:
	if not default_world_model:
		return

	var layer := FIRST_PERSON_HIDDEN_WORLD_MODEL_LAYER if _hide_world_model_from_first_person else WORLD_MODEL_LAYER
	_set_visual_layer(default_world_model, layer)

func _apply_model_offsets(node: Node, position_offset: Vector3, rotation_offset_degrees: Vector3) -> void:
	if node is Node3D:
		node.position = position_offset
		node.rotation_degrees = rotation_offset_degrees

func _apply_material_overrides(root: Node, material_overrides: Array[CharacterMaterialOverride]) -> void:
	for material_override in material_overrides:
		if material_override == null or material_override.material == null:
			continue

		var target := root.get_node_or_null(material_override.target_path) if not material_override.target_path.is_empty() else root
		if target == null:
			push_warning("Character material override target not found: %s" % material_override.target_path)
			continue

		_apply_material_override(target, material_override.surface_index, material_override.material)

func _apply_material_override(node: Node, surface_index: int, material: Material) -> void:
	if node is GeometryInstance3D and not node is MeshInstance3D and surface_index < 0:
		node.material_override = material

	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if surface_index >= 0:
			mesh_instance.set_surface_override_material(surface_index, material)
		elif mesh_instance.mesh:
			for index in mesh_instance.mesh.get_surface_count():
				mesh_instance.set_surface_override_material(index, material)

	for child in node.get_children():
		_apply_material_override(child, surface_index, material)

func _hold_inventory_item(item: Node3D) -> void:
	if item == null:
		return

	_parent_held_inventory_item(item)
	item.visible = true
	_call_inventory_item_hook(item, "held")

func refresh_held_inventory_item_parent() -> void:
	var item := get_selected_inventory_item()
	if item and item.visible:
		_parent_held_inventory_item(item)

func _parent_held_inventory_item(item: Node3D) -> void:
	var parent: Node = inventory_hold_point if inventory_hold_point else self
	var use_view_model := is_player_controlled and cam_first and cam_first.current
	var model := view_model_instance if use_view_model else world_model_instance
	var visual_layer := VIEW_MODEL_LAYER if use_view_model else world_model_visual_layer
	if model and "held_item_attachment" in model:
		var attachment := model.held_item_attachment as Node
		if attachment:
			parent = attachment
	_reparent_inventory_item(item, parent)
	_set_visual_layer(item, visual_layer)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO

func _unhold_inventory_item(item: Node3D) -> void:
	if item == null:
		return

	_call_inventory_item_hook(item, "no_longer_held")
	_parent_item_for_storage(item)
	item.visible = false

func _parent_item_for_storage(item: Node3D) -> void:
	var parent := inventory_storage_root if inventory_storage_root else self
	_reparent_inventory_item(item, parent)
	_set_visual_layer(item, world_model_visual_layer)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO

func _reparent_inventory_item(item: Node3D, new_parent: Node) -> void:
	if item.get_parent() == new_parent:
		return

	if item.get_parent():
		item.get_parent().remove_child(item)
	new_parent.add_child(item)

func _call_inventory_item_hook(item: Node3D, hook_name: StringName) -> void:
	if item and item.has_method(hook_name):
		item.call(hook_name, self)

func _setup_editor_world_model() -> void:
	if not is_inside_tree():
		return

	_clear_character_nodes()
	_set_default_world_model_visible(character_definition == null or character_definition.world_model_scene == null)

	if character_definition == null or character_definition.world_model_scene == null or world_model_root == null:
		return

	world_model_instance = character_definition.world_model_scene.instantiate()
	world_model_instance.name = "EditorWorldModelPreview"
	world_model_root.add_child(world_model_instance)
	_apply_model_offsets(
		world_model_instance,
		character_definition.world_model_position_offset,
		character_definition.world_model_rotation_offset_degrees
	)
	_apply_world_model_visual_layers()

func _on_character_definition_changed() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		_setup_editor_world_model()

func _set_default_world_model_visible(is_visible: bool) -> void:
	if default_world_model:
		default_world_model.visible = is_visible

func _on_water_body_entered(body: Node3D, area: Area3D) -> void:
	if body == self:
		if water_bodies.is_empty():
			entered_water.emit()
		if not water_bodies.has(area):
			water_bodies.append(area)

func _on_water_body_exited(body: Node3D, area: Area3D) -> void:
	if body == self:
		water_bodies.erase(area)
		if water_bodies.is_empty():
			exited_water.emit()

func _on_head_area_entered(area: Area3D) -> void:
	if area.is_in_group("water_body"):
		if head_water_bodies.is_empty():
			head_entered_water.emit()
		if not head_water_bodies.has(area):
			head_water_bodies.append(area)

func _on_head_area_exited(area: Area3D) -> void:
	if area.is_in_group("water_body"):
		head_water_bodies.erase(area)
		if head_water_bodies.is_empty():
			head_exited_water.emit()
