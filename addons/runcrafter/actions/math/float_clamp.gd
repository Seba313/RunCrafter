@tool
class_name RCFloatClamp
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Clamps a Float variable between Min and Max."

@export var variable: String = ""
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, clampf(float(get_var(variable)), min_value, max_value))
