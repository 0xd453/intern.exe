class_name Browser
extends XPWindow

signal page_loaded

const SCENE_FAVORITE := preload("res://Scenes/Windows/Browser/Components/favorite_button.tscn")
const START := "start"

@export var scene_start: PackedScene
@export var scene_without_connection: PackedScene
@export var scene_no_found: PackedScene

var page: BasePage = null
var page_name: String = ""
var loading: bool = false

var _state: Dictionary
var _title_base: String = ""
var _title_page: String = ""
var _generation: int = 0


func _ready() -> void:
	super()
	_title_base = title
	_state = AppRegistry.state.get_or_add("browser", { "history": [START], "index": 0 })
	%BtnBack.pressed.connect(back)
	%BtnForward.pressed.connect(forward)
	%BtnReload.pressed.connect(reload)
	Utils.clear_children(%ListFavorites)
	_build_favorites()
	_load(current_url(), false)


func _build_favorites() -> void:
	for website in Content.websites:
		if not website.get("favorite", false) or not Game.is_website_unlocked(website):
			continue
		var fav: Button = SCENE_FAVORITE.instantiate()
		fav.text = website["title"]
		fav.name = "Favorite_" + str(website["id"])
		var host: String = website["host"]
		fav.pressed.connect(
			func() -> void:
				navigate(host + "/"),
		)
		%ListFavorites.add_child(fav)


func current_url() -> String:
	return _state["history"][_state["index"]]


func can_back() -> bool:
	return _state["index"] > 0


func can_forward() -> bool:
	return _state["index"] < _state["history"].size() - 1


func navigate(url: String, animate: bool = true) -> void:
	var info := parse(url)
	var hist: Array = _state["history"]
	hist.resize(_state["index"] + 1)
	hist.append(info["url"])
	_state["index"] = hist.size() - 1
	_load(info["url"], animate)


func back() -> void:
	if can_back():
		_state["index"] -= 1
		_load(current_url(), true)


func forward() -> void:
	if can_forward():
		_state["index"] += 1
		_load(current_url(), true)


func reload() -> void:
	_load(current_url(), true)


func back_on_case(case_id: String) -> void:
	var url := "%s/case/%s" % [Content.config.get("portal_domain", ""), case_id]
	if can_back() and _state["history"][_state["index"] - 1] == url:
		back()
	else:
		navigate(url)


func parse(url: String) -> Dictionary:
	var u := url.strip_edges()
	if u == START:
		return { "host": START, "path": "/", "url": START }
	if u.begins_with("/"):
		u = _host_current() + u
	var bar := u.find("/")
	var host := u if bar == -1 else u.substr(0, bar)
	var path := "/" if bar == -1 else u.substr(bar)
	if path.length() > 1 and path.ends_with("/"):
		path = path.substr(0, path.length() - 1)
	host = host.to_lower()
	return { "host": host, "path": path, "url": host + path }


func _host_current() -> String:
	var current := current_url()
	if current == START:
		return Content.config.get("portal_domain", "")
	return parse(current)["host"]


func _load(url: String, animate: bool) -> void:
	_generation += 1
	var g := _generation
	_clear_page()
	_update_bar()
	if animate:
		loading = true
		var time := float(Content.config.get("loading_time", 0.7))
		_title_page = Content.t("nav.loading")
		_update_title()
		%Loading.start(time)
		await get_tree().create_timer(time).timeout
		if g != _generation or not is_inside_tree():
			return
	loading = false
	%Loading.stop()
	_build_page(parse(url))


func _build_page(info: Dictionary) -> void:
	var scene: PackedScene = null
	var website: Dictionary = { }
	var params: Dictionary = { "path": info["path"] }
	if info["host"] == START:
		scene = scene_start
	else:
		website = Content.get_website(info["host"])
		if website.is_empty() or not Game.is_website_unlocked(website):
			scene = scene_without_connection
			params["address"] = info["url"]
			website = { }
		else:
			for route in website["pages"]:
				var target: String = website["pages"][route]
				if route == info["path"]:
					scene = load(target)
					break
				if route.ends_with("/*"):
					var prefix: String = route.substr(0, route.length() - 1) # "/case/"
					if info["path"].begins_with(prefix) and info["path"].length() > prefix.length():
						scene = load(target)
						params["id"] = info["path"].substr(prefix.length())
						params["ip"] = params["id"]
						break
			if scene == null:
				scene = scene_no_found
				params["address"] = info["url"]
	var page_node: BasePage = scene.instantiate()
	page_node.browser = self
	page_node.params = params
	page_node.website = website
	page = page_node
	page_name = scene.resource_path.get_file().get_basename().to_pascal_case()
	%Scroll.add_child(page_node)
	%Scroll.scroll_vertical = 0
	_title_page = page_node.title_page
	_update_title()
	page_loaded.emit()
	if website.get("id", "") == "portal":
		Events.tutorial_event.emit("portal_opened")


func _clear_page() -> void:
	if page != null and is_instance_valid(page):
		%Scroll.remove_child(page)
		page.queue_free()
	page = null
	page_name = ""


func _update_bar() -> void:
	%BtnBack.disabled = not can_back()
	%BtnForward.disabled = not can_forward()
	var url := current_url()
	%Address.text = "" if url == START else url


func _update_title() -> void:
	set_title(_title_base if _title_page == "" else "%s — %s" % [_title_base, _title_page])


func show_dialog(
	title_dlg: String,
	text: String,
	buttons: Array,
	headline: String = "",
	headline_variation: StringName = &"LabelTitle",
) -> XPDialog:
	return XPDialog.create(%LayerDialog, title_dlg, text, buttons, headline, headline_variation)


func name_page_current() -> String:
	return page_name


func current_page() -> BasePage:
	return page
