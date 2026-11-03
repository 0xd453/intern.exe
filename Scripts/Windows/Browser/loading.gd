class_name Loading
extends Control

var _tween: Tween


func start(duration: float) -> void:
	visible = true
	%Bar.value = 0.0
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_update, 0.0, 1.0, maxf(duration, 0.01))


func stop() -> void:
	if _tween != null:
		_tween.kill()
	visible = false


func _update(v: float) -> void:
	%Bar.value = v * 100.0
	%Points.text = ".".repeat(int(v * 12.0) % 4)
