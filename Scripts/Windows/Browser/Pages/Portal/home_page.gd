extends BasePage


func build() -> void:
	var day := Content.get_day(Game.current_day)
	var total := Game.day_cases().size()
	var done := Game.day_resolved_total()
	%Day.text = Content.t(
		"home.day",
		[day.get("title", ""), Game.current_day, Content.total_days()],
	)
	%Progress.max_value = total
	%Progress.value = done
	%Remaining.text = Content.t("home.progress", [done, total])
	if Game.day_done():
		%TileQueue.title = Content.t("home.queue_empty_title")
		%TileQueue.text_button = Content.t("home.ver_result")
	%TileManual.pressed.connect(
		func() -> void:
			go("/manual"),
	)
	%TileQueue.pressed.connect(
		func() -> void:
			go("/result" if Game.day_done() else "/queue"),
	)
	%TileLab.pressed.connect(
		func() -> void:
			go("lab.test.abc/"),
	)
