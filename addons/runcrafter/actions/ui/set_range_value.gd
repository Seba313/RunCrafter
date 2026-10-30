@tool
class_name RCSetRangeValue
extends RCAction

const CATEGORY := "UI"
const DESCRIPTION := "Sets the value of a Range (ProgressBar, Slider, SpinBox...)."

@export var target: NodePath
@export var value: float = 0.0
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var r := get_target() as Range
	if r:
		r.value = value
