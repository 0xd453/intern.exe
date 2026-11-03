class_name ToolPage
extends BasePage

@export var tool_id: String = ""

var case_id: String = ""
var case: Dictionary = { }


func build() -> void:
	var f := Content.get_tool(tool_id)
	%Title.text = f.get("name", "")
	title_page = f.get("title_page", f.get("name", ""))
	case_id = str(params.get("id", ""))
	if not Game.is_tool_unlocked(tool_id) or not Content.cases.has(case_id):
		%Details.visible = false
		%BtnBackCase.visible = false
		%File.visible = false
		%Blocked.visible = true
		return
	case = Content.get_case(case_id)
	%File.text = case["name"]
	%BtnBackCase.pressed.connect(
		func() -> void:
			browser.back_on_case(case_id),
	)
	Game.mark_tool_seen(tool_id)
	build_tool()
	Events.tutorial_event.emit(tool_id + "_opened")


func build_tool() -> void:
	pass


func tag(panel: PanelContainer, label: Label, text: String, tone: String) -> void:
	panel.theme_type_variation = { "ok": &"TagOk", "error": &"TagError", "notice": &"TagNotice" }.get(
		tone,
		&"TagNeutral",
	)
	label.text = text
