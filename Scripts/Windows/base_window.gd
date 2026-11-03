extends PanelContainer
class_name BaseWindow

@export var title: String = "":
	set = set_title
@export var icon: Texture2D:
	set = set_icon


func _ready() -> void:
	%Title.text = title
	%Icon.texture = icon
	%Icon.visible = icon != null


func set_title(v: String) -> void:
	title = v
	if is_node_ready():
		%Title.text = v


func set_icon(v: Texture2D) -> void:
	icon = v
	if is_node_ready():
		%Icon.texture = v
		%Icon.visible = v != null
