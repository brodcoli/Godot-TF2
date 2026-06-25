extends Control

var _scroll_timer: float = 0.0
var _scroll_speed: float = 0.2
var _padded_text: String = ""
var _scroll_offset: int = 0

var text = "":
	get:
		return text
	set(value):
		text = value
		if text != "":
			_padded_text = " " + text + "      "
		else:
			_padded_text = ""
		_scroll_offset = 0
		_scroll_timer = -1.0
		_update_display()

func _ready() -> void:
	text = text

func _process(delta: float) -> void:
	if _padded_text == "":
		return

	_scroll_timer += delta
	if _scroll_timer >= _scroll_speed:
		_scroll_timer -= _scroll_speed
		_scroll_offset = (_scroll_offset + 1) % _padded_text.length()
		if _scroll_offset == 0:
			_scroll_timer -= 1.0
		_update_display()

func _update_display() -> void:
	if _padded_text == "":
		%MusicPlayerText.text = ""
	else:
		%MusicPlayerText.text = _padded_text.substr(_scroll_offset) + _padded_text.substr(0, _scroll_offset)
