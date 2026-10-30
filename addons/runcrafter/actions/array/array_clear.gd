@tool
class_name RCArrayClear
extends RCAction

const CATEGORY := "Array"
const DESCRIPTION := "Removes all elements of an Array variable."

@export var variable: String = ""


func _on_enter() -> void:
	finish()
	var arr: Variant = get_var(variable)
	if arr is Array:
		arr.clear()
