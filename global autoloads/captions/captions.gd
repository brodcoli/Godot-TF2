extends Node

class Caption3D extends Label3D:
	var full_text: String = ""
	var typing_speed: float = 0.05
	var duration: float = 2.0

	var _char_index: int = 0
	var _timer: float = 0.0
	var _state: int = 0

	func _ready() -> void:
		text = ""
		if typing_speed <= 0.0:
			text = full_text
			_state = 1

	func _process(delta: float) -> void:
		if _state == 0:
			_timer += delta

			var current_wait: float = typing_speed
			if _char_index > 0:
				var last_char: String = full_text[_char_index - 1]
				if last_char in [",", ".", "!", "?"]:
					current_wait *= 3.0

			if _timer >= current_wait:
				_timer = 0.0
				_char_index += 1
				text = full_text.substr(0, _char_index)
				if _char_index >= full_text.length():
					_state = 1
					_timer = 0.0
		elif _state == 1:
			_timer += delta
			if _timer >= duration:
				_state = 2
				_timer = 0.0
		elif _state == 2:
			_timer += delta
			modulate.a = 1.0 - (_timer / 0.5)
			if _timer >= 0.5:
				queue_free()

func create_3d(text: String, global_pos: Vector3, size: float = 1.0, type_speed: float = 0.05, display_duration: float = 0.0, color: Color = Color.WHITE) -> Label3D:
	if display_duration == 0.0:
		display_duration = (text.length() * type_speed) + (text.length() * 0.03)

	var caption = Caption3D.new()
	caption.full_text = text
	caption.typing_speed = type_speed
	caption.duration = display_duration
	caption.modulate = color

	caption.pixel_size = size * 0.005
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.font_size = 32
	caption.outline_size = 4
	caption.global_position = global_pos


	var scene = get_tree().current_scene
	if scene:
		scene.add_child(caption)
	else:
		add_child(caption)

	return caption
