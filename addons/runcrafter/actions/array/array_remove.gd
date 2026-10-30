@tool
class_name RCArrayRemove
extends RCAction

const CATEGORY := "Array"
const DESCRIPTION := "Removes an element (by index) from an Array variable."

@export var variable: String = ""
@export var index: int = 0


func _on_enter() -> void:
	finish()
	var arr: Variant = get_var(variable)
	if arr is Array and index >= 0 and index < arr.size():
		arr.remove_at(index)
