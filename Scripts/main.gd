extends Control

enum State {
	TITLE,
	DAY_CARD,
	DESKTOP,
	ENDING,
}

const SCREEN_TITLE := preload("res://Scenes/Screens/title.tscn")
const SCREEN_DAY_CARD := preload("res://Scenes/Screens/day_card.tscn")
const SCREEN_DESKTOP := preload("res://Scenes/Desktop/desktop.tscn")
const SCREEN_ENDING := preload("res://Scenes/Screens/ending.tscn")

var state: State = State.TITLE
var screen_current: Control = null


func _ready() -> void:
	Events.end_workday_requested.connect(_on_end_workday)
	Events.restart_requested.connect(_restart)
	_go_to(State.TITLE)


func _go_to(new: State) -> void:
	if screen_current != null:
		remove_child(screen_current)
		screen_current.queue_free()
		screen_current = null
	state = new
	match new:
		State.TITLE:
			screen_current = SCREEN_TITLE.instantiate()
			add_child(screen_current)
			screen_current.start.connect(_start)
		State.DAY_CARD:
			screen_current = SCREEN_DAY_CARD.instantiate()
			add_child(screen_current)
			screen_current.configure(Game.current_day)
			screen_current.done.connect(
				func() -> void:
					_go_to(State.DESKTOP),
			)
		State.DESKTOP:
			screen_current = SCREEN_DESKTOP.instantiate()
			add_child(screen_current)
		State.ENDING:
			screen_current = SCREEN_ENDING.instantiate()
			add_child(screen_current)
			screen_current.configure(Game.calculate_ending())


func _start() -> void:
	Game.start_game()
	_go_to(State.DAY_CARD)


func _restart() -> void:
	Game.start_game()
	_go_to(State.DAY_CARD)


## Resultado do Dia -> "Encerrar expediente" (ou "Ver final" no último dia).
func _on_end_workday() -> void:
	if Game.advance_day():
		_go_to(State.DAY_CARD)
	else:
		_go_to(State.ENDING)


func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	# F11 para janela cheia
	if ev.keycode == KEY_F11 or (ev.keycode == KEY_ENTER and ev.alt_pressed):
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		get_viewport().set_input_as_handled()
		return
	# Atalhos pra debug
	# F1 resolve o caso como correto
	# F2 pula para o fim do dia, todos como correto
	# Ctrl+F2 resolve os casos restantes como errados
	# F3 reinicia o jogo
	if not OS.is_debug_build():
		return
	match ev.keycode:
		KEY_F1:
			if state == State.DESKTOP:
				var id := Game.debug_target_case()
				if id != "":
					Game.debug_resolve_case(id, true)
		KEY_F2:
			if state == State.DESKTOP:
				Game.debug_resolve_day(not ev.ctrl_pressed)
		KEY_F3:
			_restart()
