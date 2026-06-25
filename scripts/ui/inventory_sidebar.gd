extends Control

@onready var item_list: VBoxContainer = %ItemList
@onready var _hide_timer: Timer = %HideTimer
@onready var _item_template: PanelContainer = %InventoryItemTemplate
@onready var _selected_item_template: PanelContainer = %SelectedInventoryItemTemplate

const HIDE_DELAY := 0.8

var player: Actor

func _ready() -> void:
	player = get_owner() as Actor
	if player == null:
		player = get_parent().get_parent() as Actor

	_hide_timer.one_shot = true
	_hide_timer.wait_time = HIDE_DELAY
	_hide_timer.timeout.connect(_hide_sidebar)
	_item_template.visible = false
	_selected_item_template.visible = false
	visible = false

	if player:
		player.inventory_changed.connect(_refresh)
		player.selected_inventory_item_changed.connect(_on_selected_inventory_item_changed)
		player.inventory_item_used.connect(_hide_sidebar)

	_refresh()

func set_player_ui_visible(is_visible: bool) -> void:
	if is_visible:
		return

	_hide_sidebar()

func _refresh() -> void:
	for child in item_list.get_children():
		child.queue_free()

	if player == null:
		return

	for index in range(player.inventory.size()):
		var row := _create_item_row(player.inventory[index], index)
		item_list.add_child(row)

func _create_item_row(item: Node3D, index: int) -> Control:
	var is_selected := index == player.selected_inventory_index
	var template := _selected_item_template if is_selected else _item_template
	var row := template.duplicate() as Control
	row.visible = true

	var thumbnail := row.find_child("Thumbnail", true, false) as TextureRect
	var inventory_item := item as InventoryItem
	if thumbnail and inventory_item:
		thumbnail.texture = inventory_item.thumbnail

	var label := row.find_child("ItemName", true, false) as Label
	if label:
		label.text = _get_item_name(item)

	return row

func _on_selected_inventory_item_changed() -> void:
	_refresh()
	_show_sidebar_temporarily()

func _show_sidebar_temporarily() -> void:
	visible = true
	_hide_timer.start(HIDE_DELAY)

func _hide_sidebar() -> void:
	if _hide_timer:
		_hide_timer.stop()
	visible = false

func _get_item_name(item: Node3D) -> String:
	if item == null:
		return ""

	var item_name = item.get("item_name")
	if item_name is String and not item_name.is_empty():
		return item_name

	return item.name
