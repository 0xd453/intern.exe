extends Node

const DIR := "res://Data/"

var config: Dictionary = { }
var days: Array = []
var cases: Dictionary = { }
var rules: Dictionary = { }
var dialogs: Array = []
var endings: Dictionary = { }
var websites: Array = []
var ips: Dictionary = { }
var texts: Dictionary = { }


func _ready() -> void:
	load_everything()


func load_everything() -> void:
	config = _read("config.json", { })
	days = _read("days.json", [])
	rules = _read("rules.json", { })
	dialogs = _read("dialogs.json", [])
	websites = _read("websites.json", [])
	ips = _read("ips.json", { })
	texts = _read("texts.json", { })
	cases.clear()
	for c in _read("cases.json", []):
		cases[c["id"]] = c
	endings.clear()
	for f in _read("endings.json", []):
		endings[f["id"]] = f
	_validate()


func _read(name: String, default: Variant) -> Variant:
	var path := DIR + name
	if not FileAccess.file_exists(path):
		push_error("Content: file not found: %s" % path)
		return default
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if data == null:
		push_error("Content: invalid JSON: %s" % path)
		return default
	return data


func _validate() -> void:
	for d in days:
		for id in d.get("cases", []):
			if not cases.has(id):
				push_error("Content: day %s refer inexistent case '%s'" % [d.get("day"), id])
		if not rules.has(d.get("rules", "")):
			push_error(
				"Content: day %s refer inexistent rule '%s'" % [d.get("day"), d.get("rules")]
			)
	for m in dialogs:
		for field in ["id", "from", "trigger", "text"]:
			if not m.has(field):
				push_error("Content: chat message without field '%s': %s" % [field, m])
	for id in ["hired", "dismissed"]:
		if not endings.has(id):
			push_error("Content: ending missing on '%s' at finais.json" % id)


func total_days() -> int:
	return days.size()


func get_day(n: int) -> Dictionary:
	for d in days:
		if int(d["day"]) == n:
			return d
	push_error("Content: day %d doesn't exists" % n)
	return { }


func get_case(id: String) -> Dictionary:
	if not cases.has(id):
		push_error("Content: case '%s' doesn't exists" % id)
		return { }
	return cases[id]


func get_rules() -> Dictionary:
	return rules


func get_day_tips(n: int) -> Array:
	var key: String = get_day(n).get("rules", "")
	return rules.get(key, [])


func get_ending(id: String) -> Dictionary:
	return endings.get(id, { })


func get_dialogs_from_trigger(type: String, value: Variant) -> Array:
	var exit: Array = []
	for m in dialogs:
		var g: Dictionary = m["trigger"]
		if g.get("type", "") != type:
			continue
		var v: Variant = g.get("value")
		var equal := false
		if type == "start_day" or type == "end_day":
			equal = int(v) == int(value)
		else:
			equal = str(v) == str(value)
		if equal:
			exit.append(m)
	return exit


func get_tools() -> Array:
	return config.get("tools", [])


func get_tool(id: String) -> Dictionary:
	for f in get_tools():
		if f["id"] == id:
			return f
	return { }


func get_ip(ip: String) -> Dictionary:
	return ips.get(ip, { })


func get_website(host: String) -> Dictionary:
	for s in websites:
		if s["host"] == host:
			return s
	return { }


func get_contact(id: String) -> Dictionary:
	for c in config.get("contacts", []):
		if c["id"] == id:
			return c
	return { }


func t(key: String, args: Array = []) -> String:
	var s: String = texts.get(key, "")
	if s == "":
		push_warning("Content: text '%s' not found at textos.json" % key)
		return key
	for i in args.size():
		s = s.replace("{%d}" % i, str(args[i]))
	return s


func label(group: String, value: Variant) -> String:
	var g: Dictionary = config.get("labels", { }).get(group, { })
	return g.get(str(value), str(value))
