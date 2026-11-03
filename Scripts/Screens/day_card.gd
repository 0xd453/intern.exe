extends Control

signal done

const DURATION := 2.0

var _finished: bool = false


func configure(n: int) -> void:
	var day := Content.get_day(n)
	%TextDayCard.text = "%s, %s" % [
		day.get("title", ""),
		Content.config.get("clock_start", "09:00"),
	]
	%SubDayCard.text = Content.t("day_card.day", [n, Content.total_days()])
	get_tree().create_timer(DURATION).timeout.connect(_finish)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		_finish()


func _unhandled_key_input(ev: InputEvent) -> void:
	if (
		ev is InputEventKey and ev.pressed and not ev.echo
		and ev.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]
	):
		_finish()


func _finish() -> void:
	if _finished or not is_inside_tree():
		return
	_finished = true
	done.emit()
