extends Control
class_name DesktopIcon

signal opened(icon: DesktopIcon)
signal selected(icon: DesktopIcon)

@export var app_id: String = ""
@export var app: PackedScene
@export var label: String = ""
@export var texture: Texture2D


func _ready() -> void:
	name = "Icon_" + app_id
	%IconLabel.text = label
	%Icon.texture = texture


func set_selected(val: bool) -> void:
	%Background.theme_type_variation = &"IconSelected" if val else &"Icon"


func set_counter(n: int) -> void:
	%Badge.visible = n > 0
	%BadgeLabel.text = str(n)


func badge_visible() -> bool:
	return %Badge.visible


func badge_count() -> String:
	return %BadgeLabel.text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			selected.emit(self)
			if mouse_event.double_click:
				opened.emit(self)
			accept_event()
