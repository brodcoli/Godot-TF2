extends Node

enum TeamID { UNASSIGNED, RED, BLU, ROBOT }

var teams: Dictionary[TeamID, Team] = {
	TeamID.UNASSIGNED: _create_team(
		"Unassigned",
		"team_unassigned",
		Color(0.15, 0.15, 0.15),
		preload("res://assets/textures/no_tex.png")
	),
	TeamID.RED: _create_team(
		"RED",
		"team_red",
		Color(0.91, 0.191, 0.191, 1.0),
		preload("res://assets/textures/ui/touch_controls/touch_control_pause.png")
	),
	TeamID.BLU: _create_team(
		"BLU",
		"team_blu",
		Color(0.191, 0.215, 0.91, 1.0),
		preload("res://assets/textures/ui/touch_controls/touch_control_pause.png")
	),
	TeamID.ROBOT: _create_team(
		"Robot",
		"team_robot",
		Color(0.5, 0.5, 0.5),
		preload("res://assets/textures/ui/touch_controls/touch_control_pause.png")
	),
}

func _create_team(name: String, group_name: String, color: Color, logo: Texture2D) -> Team:
	var team = Team.new()
	team.name = name
	team.group_name = group_name
	team.color = color
	team.logo = logo
	return team

func get_team_id(team: Team) -> TeamID:
	for team_id in teams:
		if teams[team_id] == team:
			return team_id

	return TeamID.UNASSIGNED
