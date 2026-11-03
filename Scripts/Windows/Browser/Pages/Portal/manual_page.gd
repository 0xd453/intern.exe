extends BasePage

const SCENE_STEP := preload("res://Scenes/Windows/Browser/Pages/Portal/step_card.tscn")
const SCENE_TYPE := preload("res://Scenes/Windows/Browser/Pages/Portal/type_card.tscn")
const SCENE_ROW := preload("res://Scenes/Components/text_row.tscn")


func _row(text: String) -> TextRow:
	var l: TextRow = SCENE_ROW.instantiate()
	l.text = text
	return l


func build() -> void:
	for box in [%Steps, %Types, %Tips]:
		Utils.clear_children(box)
	var rules := Content.get_rules()
	var i := 1
	for row in rules.get("general", []):
		var step: StepCard = SCENE_STEP.instantiate()
		%Steps.add_child(step)
		step.configure(i, str(row))
		i += 1
	%Meta.text = str(rules.get("meta", ""))
	for g in rules.get("glossary", []):
		var c: TypeCard = SCENE_TYPE.instantiate()
		%Types.add_child(c)
		c.configure(g["type"], g["text"], g.get("signs", []))
	%TitleTips.text = Content.t("manual.tips", [Game.current_day])
	for d in Content.get_day_tips(Game.current_day):
		%Tips.add_child(_row("• " + str(d)))
	%BtnGoQueue.pressed.connect(
		func() -> void:
			go("/queue"),
	)
	Events.tutorial_event.emit("manual_visited")
