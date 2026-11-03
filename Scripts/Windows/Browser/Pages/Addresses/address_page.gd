extends BasePage

const SCENE_FIELD := preload("res://Scenes/Windows/Browser/Components/field_row.tscn")


func build() -> void:
	var ip: String = str(params.get("ip", ""))
	var data := Content.get_ip(ip)
	%Address.text = ip
	%BtnClose.pressed.connect(
		func() -> void:
			browser.back(),
	)
	if data.is_empty():
		%Card.visible = false
		%Unknown.visible = true
		return
	Utils.clear_children(%Fields)
	for pair in [
		[Content.t("field.owner"), data["owner"]],
		[Content.t("field.location"), data["location"]],
	]:
		var c: FieldRow = SCENE_FIELD.instantiate()
		%Fields.add_child(c)
		c.define(pair[0], pair[1])
	var rep: String = data["reputation"]
	%Tag.theme_type_variation = &"TagError" if rep == "suspicious" else &"TagOk"
	%TagText.text = Content.label("ip_reputation", rep)
	%Note.text = data["note"]
