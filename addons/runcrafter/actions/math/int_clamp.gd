@tool
class_name RCIntClamp
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Clamps an Int variable between Min and Max."

@export var variable: String = ""
@export var min_value: int = 0
@export var max_value: int = 100
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, clampi(int(get_var(variable)), min_value, max_value))
