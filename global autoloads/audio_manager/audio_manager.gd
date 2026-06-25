@tool
extends Node3D

@export var audio_directory: String = ""

@export_tool_button("Press to update")
var button = _do_setup

func _do_setup():

	for child in get_children():
		_free_recursive(child)


	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.25
	timer.start()
	await timer.timeout
	timer.queue_free()

	var audio_files = []
	find_audio_files(audio_directory, audio_files)


	for audio_path in audio_files:
		var stream
		if audio_path.ends_with(".mp3") or audio_path.ends_with(".wav"):
			stream = load(audio_path)


		var rel_path = audio_path.trim_prefix(audio_directory + "/")
		var folders = rel_path.get_base_dir().split("/")
		var current_node = self


		for folder in folders:
			if folder == "":
				continue

			if not current_node.has_node(folder):
				var folder_node = Node3D.new()
				folder_node.name = folder
				current_node.add_child(folder_node)
				folder_node.owner = get_tree().edited_scene_root

			current_node = current_node.get_node(folder)


		var player = AudioStreamPlayer3D.new()
		player.stream = stream
		player.name = audio_path.get_file().get_basename()
		current_node.add_child(player)
		player.owner = get_tree().edited_scene_root
		player.panning_strength = 2.0

func find_audio_files(path: String, audio_files: Array) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			var full_path = path + "/" + file_name
			if dir.current_is_dir():
				find_audio_files(full_path, audio_files)
			elif file_name.ends_with(".mp3") or file_name.ends_with(".wav"):
				audio_files.append(full_path)
			file_name = dir.get_next()

		dir.list_dir_end()

func audio_exists(audio_path: String):
	return not get_node_or_null(audio_path) == null


func _free_recursive(node: Node) -> void:
	for child in node.get_children():
		_free_recursive(child)
	node.queue_free()



@onready var _main_scene = get_tree().get_root()
@onready var _rand = RandomNumberGenerator.new()

var _following_audios: Dictionary = {}

func play(audio_path: String, pos: Vector3, volume_db: float = 0, pitch_scale: float = 1.0, global: bool = false, bus: String = "SFX"):

	var original_player = get_node(audio_path)
	if not original_player:
		push_error("Could not find audio player at path: " + audio_path)
		return

	var audio_player = original_player.duplicate() as AudioStreamPlayer3D
	_main_scene.add_child(audio_player)
	audio_player.global_position = pos

	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch_scale
	audio_player.bus = bus
	if global:
		audio_player.panning_strength = 0.0
	else:
		audio_player.panning_strength = 2.0

	audio_player.play()
	await audio_player.finished

	audio_player.queue_free()




func play_rand(audio_directory: String, pos: Vector3, volume_db: float = 0, pitch_scale: float = 1.0, avoid_index: int = -1, global: bool = false, bus: String = "SFX") -> int:

	var category_node = get_node(audio_directory)
	if not category_node:
		if get_child_count() == 0:
			push_error("Tried to play a sound effect but AudioScene is not loaded yet. If running in editor, it will load now. If this is an exported project, you will need to re-export it with audios in AudioScene loaded.")
			_do_setup()

		push_error("Could not find audio category at path: " + audio_directory)
		return -1


	var players = []
	for child in category_node.get_children():
		if child is AudioStreamPlayer3D:
			players.append(child)

	if players.is_empty():
		push_error("No audio players found in category: " + audio_directory)
		return -1


	var valid_indices = []
	for i in range(players.size()):
		if i != avoid_index or players.size() == 1:
			valid_indices.append(i)

	var chosen_index = valid_indices[_rand.randi() % valid_indices.size()]
	var original_player = players[chosen_index]
	var audio_player = original_player.duplicate() as AudioStreamPlayer3D
	_main_scene.add_child(audio_player)
	audio_player.global_position = pos

	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch_scale
	audio_player.bus = bus
	if global:
		audio_player.panning_strength = 0.0
	else:
		audio_player.panning_strength = 2.0

	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)

	return chosen_index

func play_follow(audio_path: String, node_to_follow: Node3D, volume_db: float = 0, repeat: bool = false, global: bool = false, bus: String = "SFX") -> String:
	var audio_player = AudioStreamPlayer3D.new()
	_main_scene.add_child(audio_player)

	audio_player.position = node_to_follow.global_position
	var random = RandomNumberGenerator.new()
	random.randomize()
	var key = str(randi())
	while _following_audios.has(key):
		random.randomize()
		key = str(randi())
	_following_audios[key] = [audio_player, node_to_follow]


	var stream = load(audio_path)
	audio_player.stream = stream
	audio_player.volume_db = volume_db
	audio_player.bus = bus
	if global:
		audio_player.panning_strength = 0.0
	else:
		audio_player.panning_strength = 2.0
	audio_player.play()
	if repeat:
		audio_player.finished.connect(func(): audio_player.play())
		return key
	else:
		audio_player.finished.connect(func(): stop_audio(key))
		return ""

func stop_audio(key: String):
	assert(_following_audios.has(key))
	var audio_player = _following_audios[key][0]
	_following_audios.erase(key)
	audio_player.queue_free()

func _process(delta: float) -> void:
	for key in _following_audios:
		var pair = _following_audios[key]
		var audio_player = pair[0]
		var node_to_follow = pair[1]
		audio_player.position = node_to_follow.global_position


func _list_audio_files_in_directory(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()










		if file == "":
			break
		elif not file.begins_with(".") and (file.ends_with(".mp3") or file.ends_with(".wav")):
			files.append(file)

	dir.list_dir_end()

	return files
