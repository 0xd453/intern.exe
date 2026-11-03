extends BaseWindow
class_name XPWindow

signal focused(window: XPWindow)
signal minimized(window: XPWindow)
signal restored(window: XPWindow)
signal deactivated(window: XPWindow)
signal closed(window: XPWindow)
signal title_changed(window: XPWindow)

const DRAG_MARGIN := 80.0
const TITLE_HEIGHT := 30.0

@export var app_id: String = ""
@export var init_size: Vector2 = Vector2(400, 300)
@export_enum("center", "right", "left") var init_pos: String = "center"

var flag_active := false
var flag_maximized := false
var flag_minimized := false

var _rect_restore: Rect2
var _dragging: bool = false
var _drag_offset: Vector2

var _texture_maximize: Texture2D = preload("uid://c6w1p2oyuvhai")
var _texture_restore: Texture2D = preload("uid://bim4rcvm3cgix")


func _ready() -> void:
	super()
	add_to_group("xp_window")
	%TopBar.gui_input.connect(_topbar_int)
	%MinimizeButton.pressed.connect(minimize)
	%MaximizeButton.pressed.connect(switch_maximize)
	%CloseButton.pressed.connect(close)


func start(area: Vector2) -> void:
	size = init_size
	if init_pos == "right":
		position = Vector2(area.x - init_size.x - 16.0, 24.0)
	elif init_pos == "left":
		position = Vector2(16.0, 24.0)
	else:
		position = Vector2((area.x - init_size.x) * 0.5, (area.y - init_size.y) * 0.5)
	_resettle_size()


func _resettle_size() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree() and not flag_maximized:
		size = init_size


func set_title(v: String) -> void:
	super(v)
	title_changed.emit(self)


func rect_global_content() -> Rect2:
	return %Content.get_global_rect()


func activate() -> void:
	if flag_minimized:
		flag_minimized = false
		visible = true
	move_to_front()
	_set_active(true)
	focused.emit(self)


func deactive() -> void:
	var was_active := flag_active
	_set_active(false)
	if was_active:
		deactivated.emit(self)


func _set_active(v: bool) -> void:
	flag_active = v
	theme_type_variation = &"WindowFrame" if v else &"WindowFrameInactive"
	%TopBar.theme_type_variation = &"WindowTopBar" if v else &"WindowTopBarInactive"


func minimize() -> void:
	flag_minimized = true
	visible = false
	_set_active(false)
	minimized.emit(self)


func restore() -> void:
	if not flag_minimized:
		return
	flag_minimized = false
	visible = true
	restored.emit(self)
	activate()


func switch_maximize() -> void:
	var area: Vector2 = (get_parent() as Control).size
	if flag_maximized:
		flag_maximized = false
		position = _rect_restore.position
		size = _rect_restore.size
		%MaximizeButton.icon = _texture_maximize
	else:
		flag_maximized = true
		_rect_restore = Rect2(position, size)
		position = Vector2.ZERO
		size = area
		%MaximizeButton.icon = _texture_restore


func close() -> void:
	closed.emit(self)
	queue_free()


func animate_openning() -> void:
	pivot_offset = size * 0.5
	scale = Vector2(0.92, 0.92)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)


# Arrastar e focar
func _topbar_int(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mouse_event := e as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				activate()
				if mouse_event.double_click:
					switch_maximize()
					_dragging = false
					return
				if not flag_maximized:
					_dragging = true
					_drag_offset = mouse_event.global_position - global_position
			else:
				_dragging = false
	elif e is InputEventMouseMotion and _dragging:
		var motion_event := e as InputEventMouseMotion
		var parent := get_parent() as Control
		var area: Vector2 = parent.size
		var pos: Vector2 = motion_event.global_position - _drag_offset - parent.global_position
		pos.x = clampf(pos.x, DRAG_MARGIN - size.x, area.x - DRAG_MARGIN)
		pos.y = clampf(pos.y, 0.0, area.y - TITLE_HEIGHT)
		position = pos


func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mouse_event := e as InputEventMouseButton
		if not mouse_event.pressed or not visible:
			return
		if flag_active:
			return
		var point: Vector2 = e.position
		if not get_global_rect().has_point(point):
			return

		var sib := get_parent().get_children()
		# Somente a janela mais acima do cursor é focada
		for i in range(sib.find(self) + 1, sib.size()):
			var other: Node = sib[i]
			if other is XPWindow and other.visible and other.get_global_rect().has_point(point):
				return
		activate()
