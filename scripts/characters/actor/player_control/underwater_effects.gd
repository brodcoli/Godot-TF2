extends Node

@onready var _player: Actor = $".."
@onready var _player_control: ActorPlayerControl = $"../PlayerControl"

var _master_bus_index

func _ready() -> void:
	_master_bus_index = AudioServer.get_bus_index("Master")

	%UnderwaterFilter.visible = false

	_player.head_entered_water.connect(_on_entered_water)
	_player.head_exited_water.connect(_on_exited_water)

func _process(_delta: float) -> void:
	if _player_control == null or _player_control.is_player_controlled:
		return
	%UnderwaterFilter.visible = false
	AudioServer.set_bus_effect_enabled(_master_bus_index, 0, false)

func _on_entered_water():
	if _player_control == null or not _player_control.is_player_controlled:
		return
	%UnderwaterFilter.visible = true
	AudioServer.set_bus_effect_enabled(_master_bus_index, 0, true)

func _on_exited_water():
	%UnderwaterFilter.visible = false
	AudioServer.set_bus_effect_enabled(_master_bus_index, 0, false)
