extends XPWindow

const CONTACT_SCENE = preload("res://Scenes/Windows/Messenger/contact.tscn")
const BALLOON_SCENE = preload("res://Scenes/Windows/Messenger/speech_balloon.tscn")
const RESPONSE_SCENE = preload("res://Scenes/Windows/Messenger/response_button.tscn")

var _contact: String = ""
var _lines: Dictionary = { }


func _ready() -> void:
	super()
	Utils.clear_children(%Contacts)
	for c in Content.config.get("contacts", []):
		var line: Contact = CONTACT_SCENE.instantiate()
		%Contacts.add_child(line)
		line.config(c)
		line.selected.connect(_contact_selected)
		_lines[c["id"]] = line
	ChatService.message_created.connect(_message_created)
	ChatService.changed_typing.connect(_update_typing)
	ChatService.changed_response.connect(_changed_response)
	ChatService.changed_status.connect(_update_contacts.unbind(1))
	ChatService.changed_unreads.connect(_update_contacts)
	focused.connect(
		func(_w: XPWindow) -> void:
			ChatService.define_view(true, _contact),
	)
	deactivated.connect(
		func(_w: XPWindow) -> void:
			ChatService.define_view(false, _contact),
	)
	minimized.connect(
		func(_w: XPWindow) -> void:
			ChatService.define_view(false, _contact),
	)
	_contact_selected(_initial_contact())


func _exit_tree() -> void:
	ChatService.message_created.disconnect(_message_created)
	ChatService.changed_typing.disconnect(_update_typing)
	ChatService.changed_response.disconnect(_changed_response)
	ChatService.changed_status.disconnect(_update_contacts.unbind(1))
	ChatService.changed_unreads.disconnect(_update_contacts)
	ChatService.define_view(false, "")


func _initial_contact() -> String:
	var best := ""
	var most := 0
	for c in Content.config.get("contacts", []):
		var n := int(ChatService.unreads.get(c["id"], 0))
		if n > most:
			most = n
			best = c["id"]
	if best != "":
		return best
	return Content.config["contacts"][0]["id"]


func _contact_selected(id: String) -> void:
	_contact = id
	ChatService.define_view(flag_active and visible, id)
	var c := Content.get_contact(id)
	%TalkTitle.text = Content.t("chat.talk_with", [c.get("name", id)])
	Utils.clear_children(%Messages)
	for msg in ChatService.history.get(id, []):
		_add_balloon(msg)
	_scroll_to_end()
	_update_contacts()
	_update_responses()
	_update_typing()


func _update_contacts() -> void:
	for id in _lines:
		var c := Content.get_contact(id)
		_lines[id].update(
			id == _contact,
			ChatService.status.get(id, "online"),
			c.get("role", ""),
			int(ChatService.unreads.get(id, 0)),
		)


func _message_created(contact: String, msg: Dictionary) -> void:
	if contact == _contact:
		_add_balloon(msg)
		_scroll_to_end()
	_update_contacts()


func _changed_response(contact: String) -> void:
	if contact == _contact:
		_update_responses()


func _update_typing() -> void:
	var who := ChatService.typing
	%TypingIndicator.text = "" if who == "" else Content.t(
		"chat.typing",
		[Content.get_contact(who).get("name", who)],
	)


func _update_responses() -> void:
	Utils.clear_children(%Responses)
	var p: Dictionary = ChatService.pending_responses.get(_contact, { })
	if p.is_empty():
		return
	var i := 0
	for r in p["responses"]:
		var index := i
		var b: Button = RESPONSE_SCENE.instantiate()
		b.text = r["text"]
		b.name = "Response%d" % index
		b.pressed.connect(
			func() -> void:
				ChatService.answer(_contact, index),
		)
		%Responses.add_child(b)
		i += 1


func _add_balloon(msg: Dictionary) -> void:
	var from_player: bool = msg["from"] == "you"
	var b: SpeechBalloon = BALLOON_SCENE.instantiate()
	%Messages.add_child(b)
	var name := Content.t("chat.you") if from_player else str(
		Content.get_contact(msg["from"]).get("name", msg["from"])
	)
	b.define(name, msg.get("time", ""), msg["text"], from_player)


func _scroll_to_end() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		%Scroll.scroll_vertical = int(%Scroll.get_v_scroll_bar().max_value)
