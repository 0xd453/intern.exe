extends BasePage

const SCENE_ROW := preload("res://Scenes/Components/text_row.tscn")


func build() -> void:
	Events.case_resolved.connect(_on_case_resolved)
	%BtnAnalyze.pressed.connect(
		func() -> void:
			go("/case/" + Game.current_case()),
	)
	%BtnResult.pressed.connect(
		func() -> void:
			go("/result"),
	)
	_update()


func _exit_tree() -> void:
	if Events.case_resolved.is_connected(_on_case_resolved):
		Events.case_resolved.disconnect(_on_case_resolved)


func _on_case_resolved(_id: String) -> void:
	_update.call_deferred()


func _update() -> void:
	if not is_inside_tree():
		return
	var ids := Game.day_cases()
	var done := Game.day_resolved_total()
	%Progress.max_value = ids.size()
	%Progress.value = done
	%TextProgress.text = Content.t("queue.progress", [done, ids.size()])
	var current := Game.current_case()
	%CardNext.visible = current != ""
	%CardEnd.visible = current == ""
	if current != "":
		var case := Content.get_case(current)
		%Position.text = Content.t("queue.position", [done + 1, ids.size()])
		%NextName.text = case["name"]
		%DetailNext.text = Content.t(
			"queue.detail",
			[case["sent_by"], Content.label("arrived_by", case["arrived_by"])],
		)
	Utils.clear_children(%DoneList)
	%DoneSection.visible = done > 0
	for id in ids:
		if Game.is_case_resolved(id):
			var l: TextRow = SCENE_ROW.instantiate()
			l.text = "• " + str(Content.get_case(id)["name"])
			l.theme_type_variation = &"LabelSmall"
			%DoneList.add_child(l)
