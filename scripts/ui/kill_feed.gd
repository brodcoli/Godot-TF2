extends Control

const ENTRY_LIFETIME := 5.0
const MAX_VISIBLE_NORMAL_ENTRIES := 4

@onready var _pinned_entries: VBoxContainer = %PinnedEntries
@onready var _normal_scroll: ScrollContainer = %NormalScroll
@onready var _normal_entries: VBoxContainer = %NormalEntries
@onready var _normal_template: PanelContainer = %NormalKillFeedEntryTemplate
@onready var _highlight_template: PanelContainer = %HighlightKillFeedEntryTemplate

var _actor: Actor = null
var _normal_entry_count := 0
var _is_listening := false

func _ready() -> void:
	_actor = _find_owner_actor()
	_normal_template.visible = false
	_highlight_template.visible = false
	_update_scroll_height()
	_update_listening()

func _exit_tree() -> void:
	_set_listening(false)

func _process(_delta: float) -> void:
	_update_listening()

func set_player_ui_visible(is_visible: bool) -> void:
	visible = is_visible
	_update_listening()

func _on_actor_killed(attacker: Actor, victim: Actor) -> void:
	if victim == null:
		return

	var is_about_current_actor := attacker == _actor or victim == _actor
	var entry := _create_entry(attacker, victim, is_about_current_actor)
	if is_about_current_actor:
		_pinned_entries.add_child(entry)
	else:
		_normal_entries.add_child(entry)
		_normal_entry_count += 1
		_update_scroll_height()
		call_deferred("_scroll_normal_entries_to_bottom")

	await get_tree().create_timer(ENTRY_LIFETIME).timeout
	if is_instance_valid(entry):
		if not is_about_current_actor:
			_normal_entry_count = maxi(_normal_entry_count - 1, 0)
			_update_scroll_height()
		entry.queue_free()

func _create_entry(attacker: Actor, victim: Actor, highlight: bool) -> PanelContainer:
	var template := _highlight_template if highlight else _normal_template
	var entry := template.duplicate()
	entry.unique_name_in_owner = false
	entry.visible = true

	var attacker_label := entry.get_node("EntryRow/AttackerName") as Label
	var victim_label := entry.get_node("EntryRow/VictimName") as Label
	_apply_actor_label(attacker_label, attacker)
	_apply_actor_label(victim_label, victim)

	return entry

func _apply_actor_label(label: Label, actor: Actor) -> void:
	if label == null:
		return

	label.text = _actor_name(actor)
	label.modulate = _actor_team_color(actor)

func _actor_name(actor: Actor) -> String:
	if actor == null:
		return ""
	if not actor.username.is_empty():
		return actor.username
	return actor.name

func _actor_team_color(actor: Actor) -> Color:
	if actor != null and actor.team:
		return actor.team.color
	return Color.WHITE

func _update_scroll_height() -> void:
	if _normal_scroll == null or _normal_template == null:
		return

	var visible_entries := mini(_normal_entry_count, MAX_VISIBLE_NORMAL_ENTRIES)
	var separation := _normal_entries.get_theme_constant("separation")
	var entry_height := _normal_template.custom_minimum_size.y
	_normal_scroll.custom_minimum_size.y = visible_entries * entry_height + maxi(visible_entries - 1, 0) * separation

func _scroll_normal_entries_to_bottom() -> void:
	_normal_scroll.scroll_vertical = int(_normal_scroll.get_v_scroll_bar().max_value)

func _update_listening() -> void:
	_set_listening(_actor != null and _actor.is_player_controlled and visible)

func _set_listening(should_listen: bool) -> void:
	if _is_listening == should_listen:
		return

	_is_listening = should_listen
	if _is_listening:
		add_to_group("kill_feed_listeners")
	else:
		remove_from_group("kill_feed_listeners")

func _find_owner_actor() -> Actor:
	var node: Node = self
	while node:
		if node is Actor:
			return node
		node = node.get_parent()

	return get_owner() as Actor
