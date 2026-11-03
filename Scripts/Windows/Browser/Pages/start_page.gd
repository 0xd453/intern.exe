extends BasePage

const SCENE_CARD := preload("res://Scenes/Windows/Browser/Components/link_card.tscn")


func build() -> void:
	Utils.clear_children(%Saved)
	for s in Content.websites:
		if not s.get("favorite", false) or not Game.is_website_unlocked(s):
			continue
		var c: LinkCard = SCENE_CARD.instantiate()
		%Saved.add_child(c)
		c.title = s["title"]
		c.description = s["description"]
		c.icon = load("res://Assets/icons/site_%s.png" % s["id"])
		c.text_button = Content.t("nav.open")
		var host: String = s["host"]
		c.pressed.connect(
			func() -> void:
				go(host + "/"),
		)
