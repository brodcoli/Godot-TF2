extends Resource
class_name CharacterDefinition

@export var display_name := ""
@export var world_model_scene: PackedScene
@export var world_model_position_offset := Vector3.ZERO
@export var world_model_rotation_offset_degrees := Vector3.ZERO
@export var dead_head_model_scene: PackedScene
@export var view_model_scene: PackedScene
@export var view_model_position_offset := Vector3.ZERO
@export var view_model_rotation_offset_degrees := Vector3.ZERO
@export var team_visual_overrides: Array[CharacterTeamVisualOverride] = []
@export var starting_inventory: Array[PackedScene] = []

@export var max_health := 100
@export var move_speed_multiplier := 1.0
@export var jump_power_multiplier := 1.0
@export var footstep_material_set := ""

func get_team_visual_override(team: Team) -> CharacterTeamVisualOverride:
	var team_id := TeamManager.get_team_id(team)
	for visual_override in team_visual_overrides:
		if visual_override and visual_override.team_id == team_id:
			return visual_override

	return null
