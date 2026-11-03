extends ToolPage

const SCENE_ROW := preload("res://Scenes/Windows/Browser/Pages/Lab/event_row.tscn")


func build_tool() -> void:
	Utils.clear_children(%Events)
	var clickable := Game.is_tool_unlocked("addresses")
	var seconds := 2
	for row in case["behavior"]:
		var l: EventRow = SCENE_ROW.instantiate()
		%Events.add_child(l)
		l.configure("00:%02d" % seconds, str(row), clickable)
		l.ip_pressed.connect(
			func(ip: String) -> void:
				go("addresses.test.abc/ip/" + ip),
		)
		seconds += 3
	%Tip.visible = clickable
