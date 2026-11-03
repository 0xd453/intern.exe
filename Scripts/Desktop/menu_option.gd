class_name MenuOption
extends Button

signal chosen

@export var app: PackedScene
@export var exit: bool = false


func _ready() -> void:
	pressed.connect(_on_press)


func _on_press() -> void:
	chosen.emit()
	if exit:
		get_tree().quit()
	elif app != null:
		AppRegistry.open(app)
