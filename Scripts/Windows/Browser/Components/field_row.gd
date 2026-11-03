class_name FieldRow
extends HBoxContainer


func define(key: String, value: String, variation_value: StringName = &"") -> void:
	%Key.text = key
	%Value.text = value
	if variation_value != &"":
		%Value.theme_type_variation = variation_value
