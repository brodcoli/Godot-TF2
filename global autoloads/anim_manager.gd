extends Node

var _players: Array[AnimationPlayer] = []
var _player_states: Dictionary = {}
var time_passed: float = 0.0
var total_time_passed: float = 0.0
var target_fps: float = 6.0
var frame_time: float = 1.0 / target_fps


func register_player(player: AnimationPlayer) -> void:
	if not player in _players:
		_players.append(player)
		_player_states[player] = {
			"animation": "",
			"playing": false,
			"start_time": total_time_passed,
		}
		player.speed_scale = 0.0


func unregister_player(player: AnimationPlayer) -> void:
	_players.erase(player)
	_player_states.erase(player)

func _process(delta: float) -> void:
	time_passed += delta
	total_time_passed += delta

	for i in range(_players.size() - 1, -1, -1):
		var player: AnimationPlayer = _players[i]
		player.seek(_get_seek_time(player))
		time_passed -= frame_time

func _get_seek_time(player: AnimationPlayer) -> float:
	var state: Dictionary = _player_states.get(player, {})
	var animation_name := player.current_animation
	if animation_name.is_empty() or not player.has_animation(animation_name):
		state["animation"] = animation_name
		state["playing"] = player.is_playing()
		state["start_time"] = total_time_passed
		_player_states[player] = state
		return 0.0

	var is_starting = state.get("animation", "") != animation_name or state.get("playing", false) != player.is_playing()
	if is_starting:
		state = {
			"animation": animation_name,
			"playing": player.is_playing(),
			"start_time": total_time_passed,
		}
		_player_states[player] = state

	var animation := player.get_animation(animation_name)
	var skip_time = min(frame_time, animation.length)
	var sampled_time = max(_get_sampled_time() - float(state["start_time"]), 0.0)

	if animation.loop_mode == Animation.LOOP_NONE:
		return min(sampled_time + skip_time, animation.length)

	var loop_length = animation.length - skip_time
	if loop_length <= 0.0:
		return skip_time

	return fmod(sampled_time, loop_length) + skip_time

func _get_sampled_time() -> float:
	var frame_position := total_time_passed / frame_time
	var frame_index = floor(frame_position)
	var frame_fraction = frame_position - frame_index
	return lerpf(frame_index, frame_position, pow(frame_fraction, 10.0)) * frame_time
