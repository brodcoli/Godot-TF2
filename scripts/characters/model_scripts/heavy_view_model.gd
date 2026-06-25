extends Node3D

const IDLE_ANIMATION := "hold_launcher"
const FIRE_ANIMATION := "fire_launcher"
const RELOAD_START_ANIMATION := "reload_launcher_start"
const RELOAD_ANIMATION := "reload_launcher"
const RELOAD_END_ANIMATION := "reload_launcher_end"

var actor: Actor
var _reload_item: Node3D = null
var _was_reloading := false
var _reload_sequence_active := false

@export var held_item_attachment: Node3D

@onready var _anim_player: AnimationPlayer = $heavy_viewmodel/AnimationPlayer

func setup_actor_animation(new_actor: Actor, _bridge: ActorAnimationBridge) -> void:
	actor = new_actor
	_play_idle()
	
func actor_motion(info: Dictionary) -> void:
	_update_reload_animation(info.get("selected_item"))
	if not _anim_player.is_playing():
		if _reload_sequence_active:
			_continue_reload_animation()
		else:
			_play_idle()

func actor_action(action: StringName, _info: Dictionary, _payload: Variant) -> void:
	if action == &"item_used":
		_was_reloading = false
		_reload_sequence_active = false
		_anim_player.play(FIRE_ANIMATION)

func _ready() -> void:
	_anim_player.animation_finished.connect(_on_animation_finished)

func _play_idle() -> void:
	if _anim_player.current_animation != IDLE_ANIMATION or not _anim_player.is_playing():
		_anim_player.play(IDLE_ANIMATION)

func _update_reload_animation(item: Node3D) -> void:
	var is_reloading := _item_is_reloading(item)
	if item != _reload_item:
		_reload_item = item
		_was_reloading = is_reloading
		if is_reloading:
			_start_reload_animation()
		return

	if is_reloading and not _was_reloading:
		_start_reload_animation()
	elif not is_reloading and _was_reloading and _reload_sequence_active:
		_play_reload_end()

	_was_reloading = is_reloading

func _item_is_reloading(item: Node3D) -> bool:
	return item != null and "is_reloading" in item and item.is_reloading

func _start_reload_animation() -> void:
	_reload_sequence_active = true
	_play_animation_or_idle(RELOAD_START_ANIMATION)

func _continue_reload_animation() -> void:
	if _item_is_reloading(_reload_item):
		_play_animation_or_idle(RELOAD_ANIMATION)
	else:
		_play_reload_end()

func _play_reload_end() -> void:
	if _anim_player.current_animation == FIRE_ANIMATION and _anim_player.is_playing():
		_reload_sequence_active = false
		return

	if _anim_player.current_animation == RELOAD_ANIMATION and _anim_player.is_playing():
		return

	_play_animation_or_idle(RELOAD_END_ANIMATION)

func _play_animation_or_idle(animation_name: StringName) -> void:
	if _anim_player.has_animation(animation_name):
		_anim_player.play(animation_name)
	else:
		_play_idle()

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == FIRE_ANIMATION:
		_play_idle()
	elif animation_name == RELOAD_START_ANIMATION:
		_continue_reload_animation()
	elif animation_name == RELOAD_ANIMATION:
		_continue_reload_animation()
	elif animation_name == RELOAD_END_ANIMATION:
		_reload_sequence_active = false
		_play_idle()
