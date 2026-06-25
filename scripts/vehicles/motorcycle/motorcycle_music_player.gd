extends Node

@onready var _tracks: Node3D = $Tracks
@onready var _play_btn_area: Area3D = $PlayBtnArea
@onready var _pause_btn_area: Area3D = $PauseBtnArea
@onready var _link_btn_area: Area3D = $LinkBtnArea
@onready var _btn_press_sfx: AudioStreamPlayer3D = $BtnPressSFX
@onready var _anim_player: AnimationPlayer = $"../motorcycle/AnimationPlayer"

var playlist: Array[Dictionary] = []
var base_playlist: Array[Dictionary] = []
var total_duration: float = 0.0
var current_track_index: int = -1
var current_loop_index: int = -1
const RADIO_EPOCH: float = 1704067200.0
var _is_playing: bool = false
var _last_sync_time: float = 0.0
var _process_timer: float = 0.0
const PROCESS_INTERVAL: float = 0.25

var _is_mobile_web := false

@onready var _rng = RandomNumberGenerator.new()

func _ready() -> void:
	WebLoadingManager.register_task("Motorcycle Radio")

	var is_android_web = OS.has_feature("web_android")
	var is_ios_web = OS.has_feature("web_ios")
	_is_mobile_web = is_android_web or is_ios_web




	_anim_player.play("pause_btn_push")

	if not _is_mobile_web:
		await _initialize_playlist()

	WebLoadingManager.complete_task("Motorcycle Radio")

func _initialize_playlist() -> void:
	var track_nodes = _tracks.get_children()
	for track in track_nodes:
		var length = track.stream.get_length() if track.stream else 0.0
		if length > 0.0:
			base_playlist.append({
				"node": track,
				"length": length
			})
			total_duration += length


			track.play()
			await get_tree().process_frame
			track.stop()

func _process(delta: float) -> void:
	if not _is_playing or base_playlist.is_empty() or _is_mobile_web:
		return

	_process_timer += delta
	if _process_timer < PROCESS_INTERVAL:
		return
	_process_timer = 0.0

	var current_unix_time = Time.get_unix_time_from_system()
	var elapsed_time = current_unix_time - RADIO_EPOCH

	var loop_index = int(floor(elapsed_time / total_duration))
	var loop_position = fmod(elapsed_time, total_duration)

	if current_loop_index != loop_index:
		current_loop_index = loop_index

		for track_data in base_playlist:
			track_data.node.stop()

		current_track_index = -1

		playlist = base_playlist.duplicate()
		_rng.seed = 1048576 + loop_index

		for i in range(playlist.size() - 1, 0, -1):
			var j = _rng.randi_range(0, i)
			var temp = playlist[i]
			playlist[i] = playlist[j]
			playlist[j] = temp

	var accumulated_time: float = 0.0
	for i in range(playlist.size()):
		var track_data = playlist[i]
		if loop_position < accumulated_time + track_data.length:
			var track_offset = loop_position - accumulated_time
			var track = track_data.node

			if current_track_index != i or not track.playing:
				if current_track_index >= 0 and current_track_index < playlist.size() and current_track_index != i:
					playlist[current_track_index].node.stop()

				current_track_index = i
				track.play(track_offset)
				_last_sync_time = current_unix_time
				%MusicPlayerScreen.text = track.name
			else:
				var playback_pos = track.get_playback_position()
				if abs(playback_pos - track_offset) > 0.5 and (current_unix_time - _last_sync_time) > 2.0:
					track.play(track_offset)
					_last_sync_time = current_unix_time
			return
		accumulated_time += track_data.length

func _on_play_interacted(_player: Actor) -> void:
	if _is_playing:
		return

	_anim_player.play("play_btn_push")
	_btn_press_sfx.stop()
	_btn_press_sfx.play()

	await get_tree().create_timer(0.2).timeout
	_is_playing = true

	if _is_mobile_web:
		%MusicPlayerScreen.text = "Radio is disabled on mobile devices, sorry!"


func _on_pause_interacted(_player: Actor) -> void:
	if not _is_playing:
		return

	_anim_player.play("pause_btn_push")
	_btn_press_sfx.stop()
	_btn_press_sfx.play()

	await get_tree().create_timer(0.2).timeout
	%MusicPlayerScreen.text = ""
	_is_playing = false
	for child in _tracks.get_children():
		child.stop()

func _on_link_interacted(_player: Actor) -> void:
	if not _is_playing:
		return

	_anim_player.play("link_btn_push")
	_btn_press_sfx.stop()
	_btn_press_sfx.play()

	await get_tree().create_timer(0.2).timeout

	var link: String = ""
	if current_track_index >= 0 and current_track_index < playlist.size():
		var current_node = playlist[current_track_index].node
		if current_node.has_meta("url_link"):
			link = current_node.get_meta("url_link")

	if not link.is_empty():
		PauseManager.show_link_window(link)
