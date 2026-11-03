extends ToolPage

const SCENE_FIELD := preload("res://Scenes/Windows/Browser/Components/field_row.tscn")


func build_tool() -> void:
	Utils.clear_children(%Fields)
	var a: Dictionary = case["signature"]
	for pair in [
		[Content.t("field.publisher"), a["publisher"]],
		[Content.t("field.issuer"), a["issuer"]],
		[Content.t("field.created"), a["created_at"] if a["created_at"] != "" else "—"],
	]:
		var c: FieldRow = SCENE_FIELD.instantiate()
		%Fields.add_child(c)
		c.define(pair[0], pair[1])
	var state: String = a["state"]
	tag(
		%Tag,
		%TagText,
		Content.label("signature", state),
		"ok" if state == "valid" else ("error" if state == "invalid" else "notice"),
	)
	%Note.text = a["note"]
