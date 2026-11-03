class_name BasePage
extends PanelContainer

const SCENE_BUTTON_NAV := preload("res://Scenes/Windows/Browser/Components/nav_button.tscn")

@export var title_page: String = ""
var browser: Browser = null
var params: Dictionary = { }
var website: Dictionary = { }


func _ready() -> void:
	_build_header()
	build()


func build() -> void:
	pass


func go(url: String) -> void:
	browser.navigate(url)


func _build_header() -> void:
	%Header.theme_type_variation = website.get("header", "StartHeader")
	%Brand.text = website.get("title", Content.t("nav.start_page"))
	%Sub.text = Content.t("portal.sub", [Game.current_day, Game.clock_text()])
	Utils.clear_children(%LinksNav)
	var path_current: String = params.get("path", "/")
	for item in website.get("menu", []):
		var target: String = item["path"]
		var active := path_current == target or (target != "/" and path_current.begins_with(target))
		var b: Button = SCENE_BUTTON_NAV.instantiate()
		b.text = item["text"]
		b.theme_type_variation = &"ButtonNavActive" if active else &"NavButton"
		b.pressed.connect(
			func() -> void:
				go(target),
		)
		b.name = "Nav_" + str(item["text"])
		%LinksNav.add_child(b)
