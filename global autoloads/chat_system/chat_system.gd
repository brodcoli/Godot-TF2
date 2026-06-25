extends CanvasLayer

signal msg_added(msg_text: String)
signal log_cleared()

var msg_log: Array[String] = []

func add_msg(msg_text: String) -> void:
	msg_log.append(msg_text)
	msg_added.emit(msg_text)

func add_player_msg(player_name: String, msg_text: String) -> void:
	msg_text = format_player_msg(player_name, msg_text)
	msg_log.append(msg_text)
	msg_added.emit(msg_text)

func format_player_msg(player_name: String, msg_text: String) -> String:
	return "[color=aqua]<" + player_name + ">[/color] " + msg_text

func get_log() -> Array[String]:
	return msg_log

func clear_log() -> void:
	msg_log.clear()
	log_cleared.emit()
