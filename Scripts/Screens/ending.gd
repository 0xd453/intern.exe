extends Control

const SCENE_ROW := preload("res://Scenes/Components/text_row.tscn")


func configure(ending_id: String) -> void:
	var ending := Content.get_ending(ending_id)
	var ok := ending_id == "hired"
	%EndingTitle.text = Content.t("ending.title", [ending.get("title", "")])
	%CardText.theme_type_variation = &"CardOk" if ok else &"CardError"
	%EndingText.text = str(ending.get("text", ""))
	Utils.clear_children(%Summary)
	Utils.clear_children(%Errors)
	for n in range(1, Content.total_days() + 1):
		var r := Game.get_day_result(n)
		if r.is_empty():
			continue
		var row := Content.t(
			"ending.row_day",
			[
				n,
				Content.get_day(n).get("title", ""),
				r["correct"],
				r["total"],
				int(round(float(r["pct"]) * 100.0)),
			],
		)
		var status := Content.t("ending.approved") if r["approved"] else Content.t("ending.failed")
		var l: TextRow = SCENE_ROW.instantiate()
		l.text = "%s — %s" % [row, status]
		l.theme_type_variation = &"LabelOk" if r["approved"] else &"LabelError"
		%Summary.add_child(l)
	var errors := _cases_wrong()
	%SectionErrors.visible = not ok and not errors.is_empty()
	for id in errors:
		var l: TextRow = SCENE_ROW.instantiate()
		l.text = "• " + _row_error(id)
		%Errors.add_child(l)
	%BtnPlayAgain.pressed.connect(
		func() -> void:
			Events.restart_requested.emit(),
	)


func _cases_wrong() -> Array:
	var exit: Array = []
	for n in range(1, Content.total_days() + 1):
		for id in Game.day_cases(n):
			if Game.results.has(id) and not Game.results[id]["correct"]:
				exit.append(id)
	return exit


func _row_error(id: String) -> String:
	var case := Content.get_case(id)
	var right := Content.label("verdict", case["real_verdict"])
	if case.get("real_type") != null:
		right += " (%s)" % Content.label("type", case["real_type"])
	return Content.t("ending.row_error", [case["name"], right, case.get("explanation", "")])
