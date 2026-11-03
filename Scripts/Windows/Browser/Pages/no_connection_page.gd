extends BasePage


func build() -> void:
	%Text.text = Content.t("no_connection.text", [params.get("address", "")])
	%BtnBack.pressed.connect(
		func() -> void:
			go(Content.config.get("portal_domain", "") + "/"),
	)
