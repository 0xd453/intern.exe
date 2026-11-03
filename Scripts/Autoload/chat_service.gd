extends Node

signal message_created(contact: String, msg: Dictionary)
signal changed_typing
signal changed_response(contact: String)
signal changed_status(contact: String)
signal changed_unreads

var typing_delay: float = 1.0

var history: Dictionary = { }
var unreads: Dictionary = { }
var status: Dictionary = { }
var pending_responses: Dictionary = { }
var typing: String = ""

var window_active: bool = false
var opened_contact: String = ""

var _delivered: Dictionary = { }
var _queue: Array = []
var _gen: int = 0
var _processing: bool = false


func _ready() -> void:
	Events.day_started.connect(_start_day)
	Events.day_done.connect(
		func(n: int) -> void:
			trigger("end_day", n),
	)
	Events.case_resolved.connect(
		func(id: String) -> void:
			trigger("case_resolved", id),
	)
	Events.tutorial_event.connect(
		func(name: String) -> void:
			trigger("event", name),
	)
	reload()


func reload() -> void:
	_gen += 1
	_queue.clear()
	_delivered.clear()
	history.clear()
	unreads.clear()
	status.clear()
	pending_responses.clear()
	typing = ""
	for c: Variant in Content.config.get("contacts", []):
		var id: String = c["id"]
		history[id] = []
		unreads[id] = 0
		status[id] = c.get("initial_status", "online")
	changed_typing.emit()
	changed_unreads.emit()


func _start_day(n: int) -> void:
	for c in Content.config.get("contacts", []):
		if c.get("leave", false) and n >= 2:
			status[c["id"]] = "ausente"
			changed_status.emit(c["id"])
	trigger("start_day", n)


func trigger(type: String, val: Variant) -> void:
	for m in Content.get_dialogs_from_trigger(type, val):
		var id: String = m["id"]
		if _delivered.has(id):
			continue
		if not Game.check_condition(m.get("condition")):
			continue
		_delivered[id] = true
		_enqueue(
			{ "from": m["from"], "text": m["text"], "responses": m.get("responses", []), "msg": m }
		)


func _enqueue(item: Dictionary) -> void:
	item["gen"] = _gen
	_queue.append(item)
	_process_messages()


func _process_messages() -> void:
	if _processing:
		return
	_processing = true
	while not _queue.is_empty():
		var item: Dictionary = _queue.pop_front()
		if item["gen"] != _gen:
			continue
		typing = item["from"]
		changed_typing.emit()
		await get_tree().create_timer(typing_delay).timeout
		typing = ""
		changed_typing.emit()
		if item["gen"] != _gen:
			continue
		_delivery(item)
	_processing = false


func _delivery(item: Dictionary) -> void:
	var from: String = item["from"]
	var msg: Dictionary = item.get("msg", { })
	var registry := { "from": from, "text": item["text"], "time": Game.clock_text() }
	if not history.has(from):
		history[from] = []
		unreads[from] = 0
	history[from].append(registry)
	if not (window_active and opened_contact == from):
		unreads[from] = int(unreads.get(from, 0)) + 1
	var new_status: String = msg.get("define_status", "")
	if new_status == "" and Content.get_contact(from).get("leave", false):
		new_status = "online"
	if new_status != "" and status.get(from, "") != new_status:
		status[from] = new_status
		changed_status.emit(from)
	var responses: Array = item.get("responses", [])
	if responses.is_empty():
		pending_responses.erase(from)
	else:
		pending_responses[from] = { "id": msg.get("id", ""), "responses": responses }
	changed_response.emit(from)
	message_created.emit(from, registry)
	changed_unreads.emit()
	Events.chat_notification_changed.emit()
	Events.message_arrived.emit(from)
	if not msg.is_empty():
		Events.message_delivered.emit(msg)


func answer(contact: String, id: int) -> void:
	var p: Dictionary = pending_responses.get(contact, { })
	if p.is_empty() or id < 0 or id >= p["responses"].size():
		return
	var r: Dictionary = p["responses"][id]
	pending_responses.erase(contact)
	var registry := { "from": "you", "text": r["text"], "time": Game.clock_text() }
	history[contact].append(registry)
	changed_response.emit(contact)
	message_created.emit(contact, registry)
	var reaction: String = str(r.get("contact_response", ""))
	if reaction != "":
		_enqueue({ "from": contact, "text": reaction, "responses": [] })


func mark_read(contact: String) -> void:
	if int(unreads.get(contact, 0)) != 0:
		unreads[contact] = 0
		changed_unreads.emit()
		Events.chat_notification_changed.emit()


func unread_total() -> int:
	var total := 0
	for k in unreads:
		total += int(unreads[k])
	return total


func define_view(active: bool, contact: String) -> void:
	window_active = active
	opened_contact = contact
	if active and contact != "":
		mark_read(contact)
	Events.chat_notification_changed.emit()
