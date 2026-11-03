class_name XPDialog
extends Control

signal chosen(id: String)

const Scene := preload("res://Scenes/Windows/xp_dialog.tscn")
const SCENE_BUTTON := preload("res://Scenes/Windows/dialog_button.tscn")


static func create(
	parent: Control,
	title: String,
	text: String,
	buttons: Array,
	headline: String = "",
	headline_variation: StringName = &"LabelTitle",
) -> XPDialog:
	var d: XPDialog = Scene.instantiate()
	d.name = "XPDialog"
	parent.add_child(d)
	d._build(title, text, buttons, headline, headline_variation)
	return d


func _build(
	title: String,
	text: String,
	buttons: Array,
	headline: String,
	headline_variation: StringName,
) -> void:
	%Frame.title = title
	%Text.text = text
	%Headline.visible = headline != ""
	%Headline.text = headline
	%Headline.theme_type_variation = headline_variation
	Utils.clear_children(%Buttons)
	for b in buttons:
		var id: String = b["id"]
		var btn: Button = SCENE_BUTTON.instantiate()
		btn.text = b["text"]
		btn.name = "Btn_" + id
		btn.pressed.connect(
			func() -> void:
				_choose(id),
		)
		%Buttons.add_child(btn)


func _choose(id: String) -> void:
	var parent := get_parent()
	if parent != null:
		parent.remove_child(self)
	queue_free()
	chosen.emit(id)
