extends Control

signal start


func _ready() -> void:
	%BtnStart.pressed.connect(
		func() -> void:
			start.emit(),
	)
	%BtnExit.pressed.connect(
		func() -> void:
			get_tree().quit(),
	)
