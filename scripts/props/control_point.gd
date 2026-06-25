extends Area3D
class_name ControlPoint

signal captured(team: Team)
signal capture_progress_changed(progress: float, team: Team)

const UNCAPTURED_COLOR: Color = Color(0.3, 0.3, 0.3)

@export var one_player_capture_time := 12.0
@export var capture_decay_time := 6.0

var capture_team: Team = null:
	set(value):
		if value != capture_team:
			capture_team = value
			captured.emit(capture_team)
		if capture_team:
			_set_light_color(capture_team.color)
		else:
			_set_light_color(UNCAPTURED_COLOR)

var is_capturable := false
var capture_progress := 0.0
var capture_progress_team: Team = null

var _cappers: Array[Actor] = []

func _ready() -> void:
	$control_point/lightmap_mesh.visible = false
	capture_team = capture_team

func _process(delta: float) -> void:
	if not is_capturable:
		return

	_sync_overlapping_cappers()
	var team_counts := _get_team_counts()
	#print(_cappers)
	if team_counts.is_empty():
		_move_progress(-delta / maxf(capture_decay_time, 0.001))
		return

	if team_counts.size() > 1:
		return

	var team := team_counts.keys()[0] as Team
	if team == capture_team:
		_move_progress(-delta / maxf(capture_decay_time, 0.001))
		return

	if capture_progress_team == null:
		capture_progress_team = team

	var direction := 1.0 if capture_progress_team == team else -1.0
	_move_progress(direction * delta * _harmonic(team_counts[team]) / maxf(one_player_capture_time, 0.001))

	if capture_progress <= 0.0:
		capture_progress_team = team
		capture_progress_changed.emit(capture_progress, capture_progress_team)
	elif capture_progress >= 1.0:
		capture_team = team
		capture_progress_team = null
		_set_progress(0.0)

func _set_light_color(color: Color):
	$control_point/Circle_001.set_instance_shader_parameter("light_color", Vector3(color.r, color.g, color.b))


func _on_body_entered(body: Node3D) -> void:
	if body is Actor and not _cappers.has(body):
		_cappers.append(body)


func _on_body_exited(body: Node3D) -> void:
	if body is Actor:
		_cappers.erase(body)


func _sync_overlapping_cappers() -> void:
	var overlapping_actors: Array[Actor] = []
	for body in get_overlapping_bodies():
		var actor := body as Actor
		if actor == null:
			continue

		overlapping_actors.append(actor)
		if not _cappers.has(actor):
			_cappers.append(actor)

	for actor in _cappers.duplicate():
		if not overlapping_actors.has(actor):
			_cappers.erase(actor)


func _get_team_counts() -> Dictionary:
	var counts := {}
	for actor in _cappers.duplicate():
		if not is_instance_valid(actor):
			_cappers.erase(actor)
			continue
			
		if actor.health <= 0 or actor.team == TeamManager.teams[TeamManager.TeamID.UNASSIGNED]:
			continue
			
		#print(actor.capture_value)
		var value := maxi(actor.capture_value, 0)
		if value > 0:
			counts[actor.team] = counts.get(actor.team, 0) + value
			
	return counts


func _move_progress(amount: float) -> void:
	if capture_progress <= 0.0 and amount <= 0.0:
		return

	_set_progress(capture_progress + amount)


func _set_progress(value: float) -> void:
	capture_progress = clampf(value, 0.0, 1.0)
	if capture_progress <= 0.0 and _get_team_counts().is_empty():
		capture_progress_team = null

	capture_progress_changed.emit(capture_progress, capture_progress_team)


func _harmonic(count: int) -> float:
	var rate := 0.0
	for i in range(1, count + 1):
		rate += 1.0 / float(i)

	return rate
