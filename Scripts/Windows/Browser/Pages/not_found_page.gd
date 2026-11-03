extends BasePage


func build() -> void:
	%Text.text = Content.t("not_found.text", [params.get("address", "")])
	%BtnBack.pressed.connect(
		func() -> void:
			go("/"),
	)
