extends InventoryItem

const PROJECTILE_SCENE := preload("res://scenes/items/launcher_projectile.tscn")
const MAX_AMMO := 20
const CLIP_SIZE := 4
const FIRE_DELAY := 0.8
const RELOAD_DELAY_AFTER_FIRE := 0.8#0.8#0.65
const RELOAD_TIME_PER_AMMO := 0.8
const FIRST_RELOAD_EXTRA_TIME := 0.0#15

@export var item_name := "Launcher"
@export var launch_pos: Marker3D

var auto_reload_enabled := true

var ammo := MAX_AMMO
var clip := CLIP_SIZE
var time_since_last_fire := FIRE_DELAY
var is_reloading := false
var reload_timer := 0.0

@onready var hud_side_panel := $CanvasLayer/HudSidePanel

func _ready() -> void:
	_update_hud()

func _process(delta: float) -> void:
	super._process(delta)

	time_since_last_fire += delta

	if is_held and (auto_reload_enabled or Input.is_action_pressed("reload")):
		_reload()

	_process_reload(delta)

	_update_hud()

func entered_inventory(actor: Actor) -> void:
	super.entered_inventory(actor)
	print("%s entered %s's inventory." % [item_name, actor.name])

func left_inventory(actor: Actor) -> void:
	super.left_inventory(actor)
	print("%s left %s's inventory." % [item_name, actor.name])

func held(actor: Actor) -> void:
	super.held(actor)
	print("%s is now held by %s." % [item_name, actor.name])

func no_longer_held(actor: Actor) -> void:
	super.no_longer_held(actor)
	_cancel_reload()
	print("%s is no longer held by %s." % [item_name, actor.name])

func used(actor: Actor) -> void:
	super.used(actor)
	last_use_succeeded = false


	if time_since_last_fire < FIRE_DELAY:
		return

	if launch_pos == null:
		push_warning("%s cannot fire without a launch_pos." % item_name)
		return

	if clip > 0:
		_cancel_reload()
		clip -= 1
		_update_hud()
		time_since_last_fire = 0.0
		
		last_use_succeeded = true
		await get_tree().create_timer(0.05).timeout

		var projectile := PROJECTILE_SCENE.instantiate() as LauncherProjectile
		get_tree().current_scene.add_child(projectile)
		projectile.setup(launch_pos.global_position, _get_look_target(actor), [actor, self])
		

func used_held(actor: Actor) -> void:
	used(actor)

func _reload() -> void:
	if not is_held:
		return

	if _reload_should_yield_to_fire():
		return

	if clip >= CLIP_SIZE or ammo <= 0:
		return

	if not is_reloading and time_since_last_fire < RELOAD_DELAY_AFTER_FIRE:
		return

	if not is_reloading:
		is_reloading = true
		reload_timer = -FIRST_RELOAD_EXTRA_TIME

func _cancel_reload() -> void:
	is_reloading = false
	reload_timer = 0.0

func _process_reload(delta: float) -> void:
	if not is_held:
		_cancel_reload()
		return

	if _reload_should_yield_to_fire():
		_cancel_reload()
		return

	if is_reloading:
		if clip >= CLIP_SIZE or ammo <= 0:
			_cancel_reload()
			return

		reload_timer += delta
		if reload_timer >= RELOAD_TIME_PER_AMMO:
			reload_timer = 0.0
			clip += 1
			ammo -= 1

			if clip >= CLIP_SIZE or ammo <= 0:
				is_reloading = false

func _update_hud() -> void:
	hud_side_panel.clip = clip
	hud_side_panel.amount = ammo

func _owner_holding_use() -> bool:
	return inventory_owner != null and inventory_owner.command.use_held

func _reload_should_yield_to_fire() -> bool:
	return clip > 0 and _owner_holding_use()# and time_since_last_fire >= FIRE_DELAY

func _get_look_target(actor: Actor) -> Vector3:
	actor.look_ray.force_raycast_update()
	if actor.look_ray.is_colliding():
		var collider := actor.look_ray.get_collider() as Node
		if collider != actor and not actor.is_ancestor_of(collider):
			return actor.look_ray.get_collision_point()

	return actor.look_ray.to_global(actor.look_ray.target_position)

	var look_reference := actor.get_look_reference()
	return look_reference.global_position - look_reference.global_transform.basis.z * 3.0
