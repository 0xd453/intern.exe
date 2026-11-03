class_name TypeCard
extends PanelContainer


func configure(type: String, text: String, signs: Array) -> void:
	%Type.text = type
	%Text.text = text
	var rows: Array = []
	for s in signs:
		rows.append("• " + str(s))
	%Signs.text = "\n".join(rows)
