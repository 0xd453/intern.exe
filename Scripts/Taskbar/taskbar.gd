extends Control
class_name TaskBar

signal start_pressed

const HEIGHT := 32.0
const BUTTON_SCENE := preload("uid://7quf8wgog6xb")

@onready var button_start: Button = %StartButton
@onready var _clock: Label = %Clock
@onready var _task_list: HBoxContainer = %TaskButtons

var _buttons: Dictionary = { }
var _blinking: Dictionary = { }
var _level_blink: bool = false


func _ready() -> void:
	Utils.clear_children(_task_list)
	button_start.pressed.connect(
		func() -> void:
			start_pressed.emit(),
	)
	%BlinkTimer.timeout.connect(_timer_blink)


func add_window(w: XPWindow) -> void:
	var b: Button = BUTTON_SCENE.instantiate()
	b.text = w.title
	b.icon = w.icon
	b.name = "task_" + w.app_id
	b.pressed.connect(_click_window.bind(w))
	_task_list.add_child(b)
	_buttons[w] = b
	w.title_changed.connect(
		func(_j: XPWindow) -> void:
			b.text = w.title,
	)
	w.closed.connect(remove_window)
	reload_states()


func remove_window(w: XPWindow) -> void:
	var b: Button = _buttons.get(w)
	if b != null:
		_buttons.erase(w)
		b.queue_free()


func _click_window(w: XPWindow) -> void:
	if not is_instance_valid(w):
		return
	if w.flag_minimized:
		w.restore()
	elif w.flag_active:
		w.minimize()
	else:
		w.activate()
	reload_states()


func set_blinking(app_id: String, val: bool) -> void:
	_blinking[app_id] = val
	reload_states()


func is_blinking(app_id: String) -> bool:
	return bool(_blinking.get(app_id, false))


func get_window_button(w: XPWindow) -> Button:
	return _buttons.get(w)


func reload_states() -> void:
	for w: XPWindow in _buttons:
		var b: Button = _buttons[w]
		if not is_instance_valid(w):
			continue
		if _blinking.get(w.app_id, false) and _level_blink:
			b.theme_type_variation = &"ButtonTaskBlinking"
		elif w.flag_active and w.visible:
			b.theme_type_variation = &"ButtonTaskActive"
		else:
			b.theme_type_variation = &"ButtonTask"


func _timer_blink() -> void:
	_level_blink = not _level_blink
	reload_states()


func update_clock(text: String) -> void:
	_clock.text = text
