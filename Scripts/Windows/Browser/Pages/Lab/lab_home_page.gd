extends BasePage

const SCENE_CARD := preload("res://Scenes/Windows/Browser/Components/link_card.tscn")


func build() -> void:
	var current := Game.current_case()
	if current == "":
		%File.text = Content.t("lab.without_case")
	else:
		%File.text = Content.t("lab.file", [Content.get_case(current)["name"]])
	Utils.clear_children(%Tools)
	for f in Game.unlocked_tools():
		var c: LinkCard = SCENE_CARD.instantiate()
		%Tools.add_child(c)
		c.title = f["name"]
		c.description = f["description"]
		c.icon = load(f["icon"])
		c.text_button = Content.t("lab.open")
		c.mark_new(Game.is_tool_new(f["id"]))
		var url := "%s%s" % [f["host"], str(f["path"]).replace("{case}", current)]
		c.pressed.connect(
			func() -> void:
				go(url),
		)
		c.button().disabled = current == "" and "{case}" in str(f["path"])
