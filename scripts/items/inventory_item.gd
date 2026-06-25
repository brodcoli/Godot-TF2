extends Node3D
class_name InventoryItem

const DEFAULT_THUMBNAIL := preload("res://assets/textures/no_tex.png")

var _thumbnail: Texture2D = DEFAULT_THUMBNAIL

@export var thumbnail: Texture2D:
	get:
		return _thumbnail if _thumbnail else DEFAULT_THUMBNAIL
	set(value):
		_thumbnail = value if value else DEFAULT_THUMBNAIL

var inventory_owner: Actor = null
var is_held: bool = false
var last_use_succeeded := false

func _process(_delta: float) -> void:
	var show_ui := is_held and _owner_camera_active()
	for child in get_children():
		if child is CanvasLayer:
			child.visible = show_ui

func entered_inventory(actor: Actor) -> void:
	inventory_owner = actor

func left_inventory(actor: Actor) -> void:
	if inventory_owner == actor:
		inventory_owner = null

func held(actor: Actor) -> void:
	inventory_owner = actor
	is_held = true

func no_longer_held(actor: Actor) -> void:
	if inventory_owner == actor:
		is_held = false

func used(actor: Actor) -> void:
	last_use_succeeded = true

func used_held(actor: Actor) -> void:
	used(actor)

func _owner_camera_active() -> bool:
	if inventory_owner == null:
		return false

	var camera := inventory_owner.get_viewport().get_camera_3d()
	return camera == inventory_owner.cam_first or camera == inventory_owner.cam_third
