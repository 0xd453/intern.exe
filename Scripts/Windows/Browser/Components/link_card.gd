class_name LinkCard
extends PanelContainer

signal pressed

@export var title: String = "":
	set(v):
		title = v
		if is_node_ready():
			%Title.text = v
@export_multiline var description: String = "":
	set(v):
		description = v
		if is_node_ready():
			%Description.text = v
@export var text_button: String = "Open":
	set(v):
		text_button = v
		if is_node_ready():
			%Button.text = v
@export var icon: Texture2D:
	set(v):
		icon = v
		if is_node_ready():
			%Icon.texture = v


func _ready() -> void:
	%Title.text = title
	%Description.text = description
	%Button.text = text_button
	%Icon.texture = icon
	%Button.pressed.connect(
		func() -> void:
			pressed.emit(),
	)


func button() -> Button:
	return %Button


func mark_new(value: bool) -> void:
	%New.visible = value
