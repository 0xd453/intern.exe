extends Node

var current_day: int = 1
## case_id -> {correct, verdict, type, responses, correct_questionnaire}
var results: Dictionary = { }
var warnings: int = 0
var day_results: Dictionary = { }
## case_id -> {passo, responses, verdict, type}
var drafts: Dictionary = { }
## tool_id -> bool
var seen_tools: Dictionary = { }
var last_opened_case: String = ""
var clock_minutes: float = 540.0


func start_game() -> void:
	current_day = 1
	results.clear()
	warnings = 0
	day_results.clear()
	drafts.clear()
	seen_tools.clear()
	last_opened_case = ""
	_update_clock()
	ChatService.reload()
	AppRegistry.restart()


func day_cases(n: int = -1) -> Array:
	if n < 0:
		n = current_day
	return Content.get_day(n).get("cases", [])


func current_case() -> String:
	for id in day_cases():
		if not results.has(id):
			return str(id)
	return ""


func is_case_resolved(id: String) -> bool:
	return results.has(id)


func day_resolved_total() -> int:
	var done := 0
	for id in day_cases():
		if results.has(id):
			done += 1
	return done


func pending_cases() -> Array:
	var pending: Array = []
	for id in day_cases():
		if not results.has(id):
			pending.append(id)
	return pending


func day_done() -> bool:
	return day_resolved_total() >= day_cases().size()


func is_last_day() -> bool:
	return current_day >= Content.total_days()


func unlocked_tools() -> Array:
	var ids: Array = Content.get_day(current_day).get("tools", [])
	var exit: Array = []
	for f in Content.get_tools():
		if f["id"] in ids:
			exit.append(f)
	return exit


func is_tool_unlocked(id: String) -> bool:
	return id in Content.get_day(current_day).get("tools", [])


func is_tool_new(id: String) -> bool:
	return id in Content.get_day(current_day).get("tools_new", []) and not seen_tools.has(id)


func mark_tool_seen(id: String) -> void:
	seen_tools[id] = true


func is_website_unlocked(website: Dictionary) -> bool:
	return current_day >= int(website.get("since_day", 1))


func show_request() -> bool:
	return bool(Content.get_day(current_day).get("show_request", false))


func immediate_feedback() -> bool:
	return bool(Content.get_day(current_day).get("immediate_feedback", false))


func register_verdict(
	case_id: String,
	verdict: String,
	type: String,
	responses: Array,
) -> Dictionary:
	if results.has(case_id) or case_id != current_case():
		push_warning("Game: ignoring case '%s'" % case_id)
		return { }
	var case := Content.get_case(case_id)
	var real_type: Variant = case.get("real_type")
	var correct := verdict == str(case["real_verdict"])
	if correct and verdict == "malicious":
		correct = type == str(real_type)
	var answer_key: Array = case.get("answer_key", [])
	var correct_q := 0
	for i in mini(answer_key.size(), responses.size()):
		if bool(responses[i]) == bool(answer_key[i]):
			correct_q += 1
	var res := {
		"correct": correct,
		"verdict": verdict,
		"type": type if verdict == "malicious" else "",
		"responses": responses.duplicate(),
		"correct_questionnaire": correct_q,
	}
	results[case_id] = res
	drafts.erase(case_id)
	_update_clock()
	Events.tutorial_event.emit("verdict_stamped")
	Events.case_resolved.emit(case_id)
	if day_done():
		calculate_day_result(current_day)
		Events.day_done.emit(current_day)
	return res


func calculate_day_result(n: int) -> Dictionary:
	if day_results.has(n):
		return day_results[n]
	var ids: Array = Content.get_day(n).get("cases", [])
	var correct := 0
	for id in ids:
		if results.has(id) and results[id]["correct"]:
			correct += 1
	var pct := float(correct) / maxi(ids.size(), 1)
	var approved := pct >= float(Content.config.get("approve_threshold", 0.7)) - 0.0000001
	if not approved:
		warnings += 1
	var res := { "correct": correct, "total": ids.size(), "pct": pct, "approved": approved }
	day_results[n] = res
	return res


func get_day_result(n: int) -> Dictionary:
	return day_results.get(n, { })


func advance_day() -> bool:
	if is_last_day():
		return false
	current_day += 1
	_update_clock()
	AppRegistry.restart_day()
	return true


func calculate_ending() -> String:
	return "hired" if warnings == 0 else "dismissed"


static func _to_minutes(hhmm: String) -> int:
	var parts := hhmm.split(":")
	return int(parts[0]) * 60 + int(parts[1])


func _update_clock() -> void:
	var start := _to_minutes(Content.config.get("clock_start", "09:00"))
	var end := _to_minutes(Content.config.get("clock_end", "17:00"))
	var total := day_cases().size()
	var done := day_resolved_total()
	clock_minutes = start + (end - start) * (float(done) / maxi(total, 1))
	Events.clock_changed.emit()


func clock_text() -> String:
	var m := int(round(clock_minutes))
	return "%02d:%02d" % [floori(m / 60.0), m % 60]


func check_condition(cond: Variant) -> bool:
	if cond == null or typeof(cond) != TYPE_DICTIONARY:
		return true
	var variable: Variant
	match str(cond.get("var", "")):
		"warnings":
			variable = warnings
		"current_day":
			variable = current_day
		"last_opened_case":
			variable = last_opened_case
		"tutorial_correct":
			variable = bool(results.get(Tutorial.tutorial_case(), { }).get("correct", false))
		"current_case":
			variable = current_case()
		_:
			push_warning("Game: condition variable unknown: %s" % cond)
			return false
	var value: Variant = cond.get("value")
	match str(cond.get("op", "==")):
		">":
			return variable > value
		">=":
			return variable >= value
		"==":
			return variable == value
		_:
			push_warning("Game: condition operator unknown: %s" % cond)
			return false


func debug_target_case() -> String:
	return current_case()


func debug_resolve_case(id: String, correct: bool = true) -> void:
	var case := Content.get_case(id)
	var real_type: Variant = case.get("real_type")
	var verdict := str(case["real_verdict"])
	var type := "" if real_type == null else str(real_type)
	if not correct:
		if verdict == "clean":
			verdict = "malicious"
			type = "trojan"
		else:
			verdict = "clean"
			type = ""
	register_verdict(id, verdict, type, case.get("answer_key", [false, false, false, false]))


func debug_resolve_day(correct: bool = true) -> void:
	while current_case() != "":
		debug_resolve_case(current_case(), correct)
