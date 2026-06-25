extends Node

@onready var _vehicle: Vehicle = $".."

var _was_on_floor: bool = true
var _last_y_velocity: float = 0.0

func _ready() -> void:
	_vehicle.player_entered.connect(_on_player_entered)
	_vehicle.player_exited.connect(_on_player_exited)

func _on_player_entered(_player):
	%EngineHumSFX.play()
	%EngineRevSFX.play()

func _on_player_exited(_player):
	%EngineHumSFX.stop()
	%EngineRevSFX.stop()

func _process(delta: float) -> void:
	%EngineRevSFX.volume_db = remap(_vehicle.engine_power, 0, 0.7, -35, -25)
	%EngineRevSFX.pitch_scale = remap(_vehicle.engine_power, 0, 0.7, 0.9, 1.35)

	var is_on_floor = _vehicle.is_on_floor()
	if not _was_on_floor and is_on_floor:

		if not %MotorcycleThudSFX.is_playing():
			if _last_y_velocity < -27.0:
				%MotorcycleThudSFX.volume_db = -7
				%MotorcycleThudSFX.play()
			elif _last_y_velocity < -20.0:
				%MotorcycleThudSFX.volume_db = -20
				%MotorcycleThudSFX.play()
			elif _last_y_velocity < -14.0:
				%MotorcycleThudSFX.volume_db = -22
				%MotorcycleThudSFX.play()
			elif _last_y_velocity < -10.0:
				%MotorcycleThudSFX.volume_db = -28
				%MotorcycleThudSFX.play()
			elif _last_y_velocity < -5.0:
				%MotorcycleThudSFX.volume_db = -30
				%MotorcycleThudSFX.play()

	_was_on_floor = is_on_floor
	_last_y_velocity = _vehicle.velocity.y
