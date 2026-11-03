extends Control
class_name Desktop

@onready var windows_layer: Control = $WindowsLayer
@onready var task_bar: TaskBar = $TaskBar

# app_id -> DesktopIcon
var _icons: Dictionary = { }


func _ready() -> void:
	for icon in %DesktopIcons.get_children():
		if icon is DesktopIcon:
			_icons[icon.app_id] = icon
			icon.opened.connect(
				func(i: DesktopIcon) -> void:
					AppRegistry.open(i.app),
			)
			icon.selected.connect(_select_icon)
	%Wallpaper.gui_input.connect(_click_background)
	for option in %Items.get_children():
		if option is MenuOption:
			option.chosen.connect(
				func() -> void:
					%StartMenu.visible = false,
			)
	task_bar.start_pressed.connect(_toggle_menu)
	AppRegistry.registry_desktop(self)
	Events.clock_changed.connect(_update_clock)
	Events.chat_notification_changed.connect(_update_notifications)
	_update_clock()
	_update_notifications()
	# Executa depois que todos os listeners estiverem prontos
	(func() -> void:
		Events.day_started.emit(Game.current_day)
	).call_deferred()


func _exit_tree() -> void:
	if Events.clock_changed.is_connected(_update_clock):
		Events.clock_changed.disconnect(_update_clock)
	if Events.chat_notification_changed.is_connected(_update_notifications):
		Events.chat_notification_changed.disconnect(_update_notifications)


func _input(event: InputEvent) -> void:
	# Clicar fora do menu aberto fecha o menu
	var menu: Control = %StartMenu
	if menu.visible and event is InputEventMouseButton and event.pressed:
		var point: Vector2 = event.position
		if (
			not menu.get_global_rect().has_point(point)
			and not task_bar.button_start.get_global_rect().has_point(point)
		):
			menu.visible = false


func _toggle_menu() -> void:
	%StartMenu.visible = not %StartMenu.visible


func _select_icon(icon: DesktopIcon) -> void:
	for other: DesktopIcon in _icons.values():
		other.set_selected(other == icon)


func _click_background(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			for icon: DesktopIcon in _icons.values():
				icon.set_selected(false)


func get_app_icon(app_id: String) -> DesktopIcon:
	return _icons.get(app_id)


func window_created(w: XPWindow) -> void:
	task_bar.add_window(w)
	w.focused.connect(_window_focused)
	w.minimized.connect(_window_minimized)
	w.closed.connect(_window_closed)


func _window_focused(w: XPWindow) -> void:
	for child: XPWindow in windows_layer.get_children():
		if child is XPWindow and child != w:
			child.deactive()
	task_bar.reload_states()
	_update_notifications()


func _window_minimized(w: XPWindow) -> void:
	_activate_top_window(w)
	task_bar.reload_states()
	_update_notifications()


func _window_closed(w: XPWindow) -> void:
	_activate_top_window(w)
	# Janela ainda está em cena, tem que atualizar depois que sair
	(func() -> void:
		task_bar.reload_states()
		_update_notifications()
	).call_deferred()


func _activate_top_window(w: XPWindow) -> void:
	var children := windows_layer.get_children()
	children.reverse()
	for child: XPWindow in children:
		if child is XPWindow and child != w and child.visible and not child.is_queued_for_deletion():
			child.activate()
			return


func _update_clock() -> void:
	if task_bar != null:
		task_bar.update_clock(Game.clock_text())


func _update_notifications() -> void:
	if task_bar == null or not _icons.has("msn"):
		return
	var n := ChatService.unread_total()
	var window := AppRegistry.find_window("msn")
	_icons["msn"].set_counter(n if window == null else 0)
	var blink := n > 0 and window != null and not (window.flag_active and window.visible)
	task_bar.set_blinking("msn", blink)
