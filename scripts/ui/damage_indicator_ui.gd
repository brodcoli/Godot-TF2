extends Node
class_name DamageIndicatorUI

const DAMAGE_LABEL_SCENE := preload("res://scenes/ui/damage_label.tscn")

@onready var _hud: CanvasLayer = $"../HUD" as CanvasLayer
@onready var _actor: Actor = get_parent().get_parent() as Actor

var _player_ui_visible := false

func set_player_ui_visible(is_visible: bool) -> void:
	_player_ui_visible = is_visible

func show_damage_indicator(amount: int, location: Vector3) -> void:
	if not _player_ui_visible or _actor == null or not _actor.is_player_controlled or _hud == null:
		return

	var damage_label := DAMAGE_LABEL_SCENE.instantiate()
	damage_label.amount = amount
	damage_label.location = location
	_hud.add_child(damage_label)
