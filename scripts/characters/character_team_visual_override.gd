extends Resource
class_name CharacterTeamVisualOverride

@export var team_id := TeamManager.TeamID.UNASSIGNED
@export var world_model_scene: PackedScene
@export var view_model_scene: PackedScene
@export var world_model_materials: Array[CharacterMaterialOverride] = []
@export var view_model_materials: Array[CharacterMaterialOverride] = []
