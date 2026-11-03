extends BasePage

const SCENE_CHIP := preload("res://Scenes/Windows/Browser/Pages/Addresses/ip_chip.tscn")


func build() -> void:
	var current := Game.current_case()
	Utils.clear_children(%Chips)
	var found := false
	if current != "":
		var re := RegEx.create_from_string("(\\d{1,3}(?:\\.\\d{1,3}){3})")
		for row in Content.get_case(current)["behavior"]:
			var m := re.search(str(row))
			if m != null:
				var ip := m.get_string(1)
				var b: Button = SCENE_CHIP.instantiate()
				b.text = ip
				b.pressed.connect(
					func() -> void:
						go("/ip/" + ip),
				)
				%Chips.add_child(b)
				found = true
	%WithoutIps.visible = not found
