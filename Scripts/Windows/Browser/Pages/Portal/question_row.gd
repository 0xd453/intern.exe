class_name QuestionRow
extends PanelContainer

signal answered(value: bool)


func _ready() -> void:
	var group := ButtonGroup.new()
	%BtnYes.button_group = group
	%BtnNo.button_group = group
	%BtnYes.toggled.connect(
		func(linked: bool) -> void:
			if linked:
				answered.emit(true),
	)
	%BtnNo.toggled.connect(
		func(linked: bool) -> void:
			if linked:
				answered.emit(false),
	)


func configure(number: int, text: String, value: Variant) -> void:
	var yes: Button = %BtnYes
	var no: Button = %BtnNo
	%Text.text = "%d. %s" % [number, text]
	name = "Question%d" % number
	yes.name = "P%d_yes" % number
	no.name = "P%d_no" % number
	if value != null:
		(yes if bool(value) else no).set_pressed_no_signal(true)
