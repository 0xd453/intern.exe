class_name EventRow
extends PanelContainer

signal ip_pressed(ip: String)


func configure(time: String, row: String, ip_clickable: bool) -> void:
	%Time.text = time
	%Chip.visible = false
	%After.text = ""
	%After.visible = false
	var re := RegEx.create_from_string("(\\d{1,3}(?:\\.\\d{1,3}){3})")
	var m := re.search(row)
	if m == null:
		%Before.text = row
		return
	var ip := m.get_string(1)
	%Before.text = row.substr(0, m.get_start()).strip_edges(false, true)
	%After.text = row.substr(m.get_end()).strip_edges(true, false)
	%After.visible = %After.text != ""
	%Chip.text = ip
	%Chip.visible = true
	%Chip.disabled = not ip_clickable
	%Chip.tooltip_text = "" if ip_clickable else "Libere a Consulta de endereços para investigar."
	%Chip.pressed.connect(
		func() -> void:
			ip_pressed.emit(ip),
	)
