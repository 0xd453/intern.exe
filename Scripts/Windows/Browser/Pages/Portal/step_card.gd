class_name StepCard
extends PanelContainer


func configure(number: int, text: String) -> void:
	%Number.text = str(number)
	%Text.text = text
