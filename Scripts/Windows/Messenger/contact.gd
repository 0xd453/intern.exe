extends PanelContainer
class_name Contact

signal selected(id: String)

var contact_id: String = ""


func _ready() -> void:
	%Button.pressed.connect(
		func() -> void:
			selected.emit(contact_id),
	)


func config(contact: Dictionary) -> void:
	contact_id = contact["id"]
	name = "Contact_" + contact_id
	%Name.text = contact["name"]
	update(false, "online", contact["role"], 0)


func update(is_selected: bool, status: String, role: String, unreads: int) -> void:
	theme_type_variation = &"ContactSelected" if is_selected else &"Contact"
	%Status.theme_type_variation = &"StatusOnline" if status == "online" else &"StatusAway"
	%Info.text = "%s - %s" % [role, status]
	%Badge.visible = unreads > 0
	%BadgeText.text = str(unreads)
