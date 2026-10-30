@tool
class_name RCArrayGet
extends RCAction

const CATEGORY := "Array"
const DESCRIPTION := "Reads an element of an Array variable."

@export var variable: String = ""
@export var index: int = 0
@export var store_result: String = ""
@export var out_of_range_event: String = ""


func _on_enter() -> void:
	finish()
	var arr: Variant = get_var(variable)
	if arr is Array and index >= -arr.size() and index < arr.size():
		store(store_result, arr[index])
	else:
		send_event(out_of_range_event)
