extends Node


func _ready() -> void:
	Events.message_delivered.connect(_on_message)


func tutorial_case() -> String:
	var cases: Array = Content.get_day(1).get("cases", [])
	return "" if cases.is_empty() else str(cases[0])


func _on_message(msg: Dictionary) -> void:
	if msg.get("tutorial", false):
		_show_chat()


func _show_chat() -> void:
	var chat := AppRegistry.find_window("msn")
	if chat == null:
		return
	if chat.flag_minimized:
		chat.restore()
	elif not chat.flag_active:
		chat.activate()
