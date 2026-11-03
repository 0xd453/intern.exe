extends Node

var desktop: Node = null
var windows: Dictionary = { }
# Estado das janelas
var state: Dictionary = { }


func registry_desktop(d: Node) -> void:
	desktop = d
	windows.clear()


func restart() -> void:
	windows.clear()
	state.clear()


func restart_day() -> void:
	state.erase("browser")


func find_window(id: String) -> XPWindow:
	var w: Variant = windows.get(id)
	if w != null and is_instance_valid(w):
		return w
	return null


func open(scene: PackedScene) -> XPWindow:
	var window: XPWindow = scene.instantiate()
	var exists := find_window(window.app_id)
	if exists != null:
		window.free()
		if exists.flag_minimized:
			exists.restore()
		else:
			exists.activate()
		return exists
	var layer: Control = desktop.windows_layer
	layer.add_child(window)
	window.start(layer.size)
	window.closed.connect(_closed_window)
	windows[window.app_id] = window
	desktop.window_created(window)
	window.animate_openning()
	window.activate()
	Events.tutorial_event.emit(window.app_id + "_opened")
	return window


func _closed_window(window: XPWindow) -> void:
	if windows.get(window.app_id) == window:
		windows.erase(window.app_id)
