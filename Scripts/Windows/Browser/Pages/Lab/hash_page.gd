extends ToolPage

const SCENE_FIELD := preload("res://Scenes/Windows/Browser/Components/field_row.tscn")


func build_tool() -> void:
	Utils.clear_children(%Fields)
	var h: Dictionary = case["hash"]
	for pair in [[Content.t("field.hash"), h["value"]], [Content.t("field.seen"), h["seen"]]]:
		var c: FieldRow = SCENE_FIELD.instantiate()
		%Fields.add_child(c)
		c.define(pair[0], pair[1])
	var rep: String = h["reputation"]
	tag(
		%Tag,
		%TagText,
		Content.label("hash_reputation", rep),
		"error" if rep == "known_malicious" else ("ok" if rep == "known_clean" else "notice"),
	)
	%Note.text = h["note"]
