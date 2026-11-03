extends BasePage

const SCENE_CARD := preload("res://Scenes/Windows/Browser/Pages/Portal/result_card.tscn")


func build() -> void:
	%BtnBackQueue.pressed.connect(
		func() -> void:
			go("/queue"),
	)
	if not Game.day_done():
		%Notice.visible = true
		%Result.visible = false
		return
	var r := Game.get_day_result(Game.current_day)
	%Correct.text = Content.t("result.correct", [r["correct"], r["total"]])
	%Percentage.text = Content.t("result.percentage", [int(round(float(r["pct"]) * 100.0))])
	%Seal.theme_type_variation = &"ApprovedSeal" if r["approved"] else &"FailedSeal"
	%SealText.text = Content.t("result.approved") if r["approved"] else Content.t("result.failed")
	%SealText.theme_type_variation = &"LabelOk" if r["approved"] else &"LabelError"
	if r["approved"]:
		%Message.text = Content.t(
			"result.text_approved",
			[int(round(float(Content.config.get("approve_threshold", 0.7)) * 100.0))],
		)
		%Message.theme_type_variation = &"LabelOk"
	else:
		%Message.text = Content.t("result.warning", [Game.warnings])
		%Message.theme_type_variation = &"LabelError"
	Utils.clear_children(%Cases)
	for id in Game.day_cases():
		var c: ResultCard = SCENE_CARD.instantiate()
		%Cases.add_child(c)
		c.configure(Content.get_case(id), Game.results[id])
	var text_end := Content.t("result.ver_ending") if Game.is_last_day() else Content.t(
		"result.end"
	)
	%BtnEnd.text = text_end
	%BtnEnd2.text = text_end
	%BtnEnd.pressed.connect(
		func() -> void:
			Events.end_workday_requested.emit(),
	)
	%BtnEnd2.pressed.connect(
		func() -> void:
			Events.end_workday_requested.emit(),
	)
