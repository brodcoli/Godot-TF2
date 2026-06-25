extends Area3D
class_name SpawnPoint

@export var team: TeamManager.TeamID = TeamManager.TeamID.UNASSIGNED
@export var spawn_count: int = 2
@export var make_one_a_player: bool = false

const _actor_scene = preload("res://scenes/characters/actor.tscn")
const _default_char_def = preload("res://scenes/characters/character_definitions/heavy_chardef.tres")
const _usernames1: Array[String] = [
	"Scout",
	"Soldier",
	"Pyro",
	"Demoman",
	"Heavy",
	"Engineer",
	"Sniper",
	"Medic",
	"Spy",
	"Nothing",
	"Nobody",
	"Rocket",
	"Wrench",
	"Dispenser",
	"Chucklenuts",
	"Bread",
	"Sandvich",
	"Bot",
	"Eagle",
	"Crowbar",
	"Mann",
	"Maggot",
	"Pootis",
	"Thing",
	"Gunslinger",
	"Cowmangler",
	"Gibus",
	"Pan",
	"Phlog",
	"Administrator",
	"PoopyJoe",
]
const _usernames2: Array[String] = [
	"Plump_*",
	"Ripe*",
	"Fresh*",
	"IttyBitty*",
	"Tiny*",
	"Mega*",
	"Enlarged*",
	"I_Am_*",
	"Caramelized*",
	"Roasted*",
	"Baby*",
	"Crazed*",
	"Diaper_Wearing_*",
	"Scottish*",
	"French*",
	"Crying*",
	"Kissable*",
	"*_Plushy",
	"Unusual*",
	"The_*_Is_A_Spy",
	"The_Ultimate_*",
	"*_Body_Pillow",
	"Mean_Old_*",
	"Xx_*_xX",
	"*Pro2009",
	"TheEpitomeOf*",
	"*.jpeg",
	"*.avi",
	"*TF2",
	"*FromBoston",
	"Weakest*InAustralia",
	"Australium_*",
	"*IsFairAndBalanced",
	"Guess_We_Maining_*_Now",
	"*(evil)",
	"*(f2p)",
	"YaBoy*",
	"*IsntRealItCantHurtYou",
	"Hey_Guys_*_Here",
	"The_Reverse_*",
	"*_On_Steroids",
	"Three*sInATrenchcoat",
	"TheReal*",
	"*OnAGoodDay",
	"*Gaming",
	"The*OfYourDreams",
	"10x*",
]

func _ready() -> void:
	var actors: Array[Actor] = []
	var used_usernames := {}
	for i in spawn_count:
		var actor: Actor = _actor_scene.instantiate()
		actor.character_definition = _default_char_def
		actor.team = TeamManager.teams[team]
		actor.username = _generate_random_username(used_usernames)
		add_child(actor)
		actor.global_position = _get_random_spawn_position()
		actor.entered_dead_state.connect(_on_actor_dead.bind(actor))
		actors.append(actor)
	if make_one_a_player:
		var actor: Actor = actors.pick_random()
		await get_tree().process_frame
		actor.is_player_controlled = true

	for actor: Actor in actors:
		if not actor.is_player_controlled:
			actor.auto_behavior.enabled = true


func _get_random_spawn_position() -> Vector3:
	var spawn_shape := _get_random_box_collision_shape()
	if spawn_shape == null:
		return global_position

	var box_shape := spawn_shape.shape as BoxShape3D
	var half_size := box_shape.size * 0.5
	var local_position := Vector3(
		randf_range(-half_size.x, half_size.x),
		randf_range(-half_size.y, half_size.y),
		randf_range(-half_size.z, half_size.z)
	)
	return spawn_shape.to_global(local_position)

func _get_random_box_collision_shape() -> CollisionShape3D:
	var spawn_shapes: Array[CollisionShape3D] = []
	var total_volume := 0.0
	for child in get_children():
		var collision_shape := child as CollisionShape3D
		if collision_shape and collision_shape.shape is BoxShape3D:
			spawn_shapes.append(collision_shape)
			total_volume += _get_box_volume(collision_shape.shape)

	if spawn_shapes.is_empty():
		return null

	var volume_pick := randf() * total_volume
	var accumulated_volume := 0.0
	for spawn_shape in spawn_shapes:
		accumulated_volume += _get_box_volume(spawn_shape.shape)
		if volume_pick <= accumulated_volume:
			return spawn_shape

	return spawn_shapes.back()

func _get_box_volume(shape: Shape3D) -> float:
	var box_shape := shape as BoxShape3D
	if box_shape == null:
		return 0.0

	return box_shape.size.x * box_shape.size.y * box_shape.size.z

func _generate_random_username(used_usernames: Dictionary) -> String:
	for attempt in 20:
		var username = _usernames2.pick_random().replace("*",_usernames1.pick_random())
		if not used_usernames.has(username):
			used_usernames[username] = true
			return username

	var fallback_username := "Player%d" % (used_usernames.size() + 1)
	used_usernames[fallback_username] = true
	return fallback_username

func _on_actor_dead(actor: Actor) -> void:
	await get_tree().create_timer(5.0).timeout
	actor.respawn_at(_get_random_spawn_position())
