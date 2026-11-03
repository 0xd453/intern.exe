extends BasePage

const SCENE_BUTTON_TOOL := preload("res://Scenes/Windows/Browser/Components/tool_button.tscn")
const SCENE_FIELD := preload("res://Scenes/Windows/Browser/Components/field_row.tscn")
const SCENE_QUESTION := preload("res://Scenes/Windows/Browser/Pages/Portal/question_row.tscn")

var case_id: String = ""
var case: Dictionary = { }
var draft: Dictionary = { }

var _stamping: bool = false


func build() -> void:
	case_id = str(params.get("id", ""))
	Events.case_resolved.connect(_on_case_resolved)
	%BtnQueue.pressed.connect(
		func() -> void:
			go("/queue"),
	)
	%BtnNoticeQueue.pressed.connect(
		func() -> void:
			go("/queue"),
	)
	if not (case_id in Game.day_cases()):
		title_page = Content.t("case.no_found_title")
		_notice(Content.t("case.no_found", [case_id]))
		return
	case = Content.get_case(case_id)
	title_page = Content.t("case.title_page", [Game.day_cases().find(case_id) + 1])
	if Game.is_case_resolved(case_id):
		_notice(_text_review())
		return
	if case_id != Game.current_case():
		_notice(Content.t("case.out_of_turn"))
		return
	_build_analysis()


func _exit_tree() -> void:
	if Events.case_resolved.is_connected(_on_case_resolved):
		Events.case_resolved.disconnect(_on_case_resolved)


func _notice(text: String) -> void:
	%Analysis.visible = false
	%HeaderCase.visible = false
	%Notice.visible = true
	%NoticeText.text = text

# --- Montagem da análise -----------------------------------------------------


func _build_analysis() -> void:
	Game.last_opened_case = case_id
	if not Game.drafts.has(case_id):
		Game.drafts[case_id] = { "responses": [null, null, null, null], "verdict": "", "type": "" }
	draft = Game.drafts[case_id]
	var ids := Game.day_cases()
	%TitleCase.text = Content.t("case.title", [ids.find(case_id) + 1, ids.size()])
	%FileName.text = case["name"]
	_build_sheet()
	_build_tools()
	_build_decision()
	Events.tutorial_event.emit("case_opened")
	if not Game.seen_tools.is_empty():
		Events.tutorial_event.emit("case_retomado")


func _text_tool(f: Dictionary) -> String:
	var text: String = f["name"]
	if Game.is_tool_new(f["id"]):
		text += "  [%s]" % Content.t("case.new")
	return text


func _field(key: String, value: String) -> void:
	var c: FieldRow = SCENE_FIELD.instantiate()
	%Fields.add_child(c)
	c.define(key, value)


func _build_sheet() -> void:
	Utils.clear_children(%Fields)
	_field(Content.t("field.size"), case["size"])
	_field(Content.t("field.folder"), case["path"])
	_field(Content.t("field.sent_by"), case["sent_by"])
	_field(Content.t("field.arrived_by"), Content.label("arrived_by", case["arrived_by"]))
	if Game.show_request():
		_field(Content.t("field.request"), "\"%s\"" % case["request"])


func _build_tools() -> void:
	Utils.clear_children(%Tools)
	for f in Game.unlocked_tools():
		var b: Button = SCENE_BUTTON_TOOL.instantiate()
		b.text = _text_tool(f)
		b.icon = load(f["icon"])
		b.tooltip_text = f["description"]
		b.name = "Tool_" + f["id"]
		var url: String = "%s%s" % [f["host"], str(f["path"]).replace("{case}", case_id)]
		b.pressed.connect(
			func() -> void:
				go(url),
		)
		%Tools.add_child(b)


func _build_decision() -> void:
	Utils.clear_children(%Questions)
	var questions: Array = Content.config.get("questions", [])
	for i in questions.size():
		var p: QuestionRow = SCENE_QUESTION.instantiate()
		%Questions.add_child(p)
		p.configure(i + 1, questions[i]["text"], draft["responses"][i])
		var index := i
		p.answered.connect(
			func(value: bool) -> void:
				_answer(index, value),
		)

	var group := ButtonGroup.new()
	%BtnClean.button_group = group
	%BtnMalicious.button_group = group
	%BtnClean.toggled.connect(
		func(linked: bool) -> void:
			if linked:
				_choose_verdict("clean"),
	)
	%BtnMalicious.toggled.connect(
		func(linked: bool) -> void:
			if linked:
				_choose_verdict("malicious"),
	)
	var group_type := ButtonGroup.new()
	for pair in [[%BtnTrojan, "trojan"], [%BtnAdware, "adware"], [%BtnRansomware, "ransomware"]]:
		var b: Button = pair[0]
		var type: String = pair[1]
		b.button_group = group_type
		b.toggled.connect(
			func(linked: bool) -> void:
				if linked:
					_choose_type(type),
		)
		if draft["type"] == type:
			b.set_pressed_no_signal(true)
	if draft["verdict"] == "clean":
		%BtnClean.set_pressed_no_signal(true)
	elif draft["verdict"] == "malicious":
		%BtnMalicious.set_pressed_no_signal(true)
	%TypeButtons.visible = draft["verdict"] == "malicious"
	%BtnStamp.pressed.connect(_ask_confirmation)
	_update_stamp()


func _answer(index: int, value: bool) -> void:
	draft["responses"][index] = value
	_update_stamp()


func _questionnaire_complete() -> bool:
	for r in draft["responses"]:
		if r == null:
			return false
	return true


func _choose_verdict(value: String) -> void:
	draft["verdict"] = value
	if value == "clean":
		draft["type"] = ""
	%TypeButtons.visible = value == "malicious"
	_update_stamp()


func _choose_type(type: String) -> void:
	draft["type"] = type
	_update_stamp()


func _verdict_valid() -> bool:
	if draft["verdict"] == "clean":
		return true
	return draft["verdict"] == "malicious" and draft["type"] != ""


func _update_stamp() -> void:
	var missing := ""
	if not _questionnaire_complete():
		missing = Content.t("case.missing_questions")
	elif draft["verdict"] == "":
		missing = Content.t("case.missing_verdict")
	elif not _verdict_valid():
		missing = Content.t("case.missing_type")
	%BtnStamp.disabled = missing != ""
	%DecisionNotice.text = missing


func _text_verdict(verdict: String, type: String) -> String:
	var t := Content.label("verdict", verdict)
	if verdict == "malicious" and type != "":
		t += " — " + Content.label("type", type)
	return t


func _ask_confirmation() -> void:
	if %BtnStamp.disabled:
		return
	var text := Content.t("case.confirm_text", [_text_verdict(draft["verdict"], draft["type"])])
	var d: XPDialog = browser.show_dialog(
		Content.t("case.confirm_title"),
		text,
		[
			{ "id": "ok", "text": Content.t("case.confirm_ok") },
			{ "id": "cancel", "text": Content.t("case.confirm_cancel") },
		],
	)
	d.chosen.connect(
		func(id: String) -> void:
			if id == "ok":
				_stamp(),
	)


func _stamp() -> void:
	_stamping = true
	var responses: Array = []
	for r in draft["responses"]:
		responses.append(bool(r))
	var res := Game.register_verdict(case_id, draft["verdict"], draft["type"], responses)
	if res.is_empty():
		_stamping = false
		return
	if Game.immediate_feedback():
		var right: bool = res["correct"]
		var d: XPDialog = browser.show_dialog(
			Content.t("case.feedback_title"),
			_text_feedback(res),
			[{ "id": "ok", "text": Content.t("case.feedback_ok") }],
			Content.t("case.feedback_right") if right else Content.t("case.feedback_errado"),
			&"LabelOk" if right else &"LabelError",
		)
		d.chosen.connect(
			func(_id: String) -> void:
				go("/queue"),
		)
	else:
		go("/queue")


func _text_feedback(res: Dictionary) -> String:
	var parts: Array = []
	if not res["correct"]:
		var real_type: Variant = case.get("real_type")
		parts.append(
			Content.t(
				"case.feedback_response",
				[
					_text_verdict(
						str(case["real_verdict"]),
						"" if real_type == null else str(real_type),
					)
				],
			)
		)
	parts.append(str(case["explanation"]))
	parts.append(Content.t("case.feedback_quest", [res["correct_questionnaire"], 4]))
	return "\n\n".join(parts)


func _on_case_resolved(id: String) -> void:
	if id == case_id and not _stamping:
		go.call_deferred("/queue")


func _text_review() -> String:
	var res: Dictionary = Game.results[case_id]
	var t := Content.t("case.review_stamp", [_text_verdict(res["verdict"], res["type"])])
	if Game.immediate_feedback():
		t += "\n\n" + _text_feedback(res)
	else:
		t += "\n\n" + Content.t("case.review_without_feedback")
	return t
