extends MarginContainer
class_name SpeechBalloon


func define(name: String, time: String, text: String, from_player: bool) -> void:
	%Name.text = name
	%Time.text = time
	%TextBody.text = text
	%Panel.theme_type_variation = &"BalloonPlayer" if from_player else &"BalloonContact"
	add_theme_constant_override("margin_left" if from_player else "margin_right", 44)
