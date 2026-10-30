@tool
class_name RCIntAdd
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Adds a value to an Int variable."

@export var variable: String = ""
@export var add: int = 1
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, int(get_var(variable)) + add)
