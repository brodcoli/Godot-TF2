extends AudioStreamPlayer3D

const WIND_VOL_MULT = 0.9

@onready var _player: Actor = $".."
@onready var _player_control: ActorPlayerControl = $"../PlayerControl"

var _last_pos := Vector3.ZERO

func _ready():
	play()
	volume_db = -100

	_last_pos = _player.global_position

func _physics_process(delta: float):
	if _player_control == null or not _player_control.is_player_controlled:
		volume_db = -100
		_last_pos = _player.global_position
		return

	var displacement = _last_pos - _player.global_position
	var speed = displacement.length() / delta if delta > 0.0 else 0.0

	var current_cam = get_viewport().get_camera_3d()
	if current_cam and current_cam.owner == self.owner:

		global_position = current_cam.global_position + -displacement.normalized()*2.0



	var wind_vol = remap(speed, 8.0, 72.0, -55, 130 * WIND_VOL_MULT)
	var wind_pitch = remap(speed, 0.0, 84.0, 0.7, 1.3)
	if wind_vol <= -50:
		wind_vol = -1000
	elif wind_vol > 80:
		wind_vol = 80
	if wind_pitch > 1.7:
		wind_pitch = 1.7
	wind_vol += 20.0
	volume_db = wind_vol
	pitch_scale = wind_pitch

	_last_pos = _player.global_position
