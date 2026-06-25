extends Control

@onready var actor: Actor = owner
@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label

const PANEL_MARGIN_HORIZONTAL := 12.0
const PANEL_MARGIN_VERTICAL := 6.0

var style := StyleBoxFlat.new()

func _ready() -> void:
	visible = false
	style = panel.get_theme_stylebox("panel").duplicate()
	style.content_margin_left = PANEL_MARGIN_HORIZONTAL
	style.content_margin_top = PANEL_MARGIN_VERTICAL
	style.content_margin_right = PANEL_MARGIN_HORIZONTAL
	style.content_margin_bottom = PANEL_MARGIN_VERTICAL
	#style.border_width_left = 1
	#style.border_width_top = 1
	#style.border_width_right = 1
	#style.border_width_bottom = 1
	#style.border_color = Color.from_string("3b332f", Color.BLACK)
	panel.add_theme_stylebox_override("panel", style)

func _process(_delta: float) -> void:
	visible = false
	if actor == null or not actor.is_player_controlled or actor.look_ray == null:
		return

	actor.look_ray.force_raycast_update()
	var other := actor.look_ray.get_collider() as Actor
	if other == null or other == actor:
		return
	if other.team != actor.team or actor.global_position.distance_to(other.global_position) > 5.0:
		return

	label.text = other.username
	style.bg_color = other.team.color
	visible = true
