@tool
class_name RCArrayContains
extends RCAction

const CATEGORY := "Array"
const DESCRIPTION := "Checks whether an Array variable contains a value."

@export var variable: String = ""
@export var value_expression: String = ""
@export var true_event: String = ""
@export var false_event: String = ""
@export var store_result: String = ""


func _on_enter() -> void:
	finish()
	var arr: Variant = get_var(variable)
	var found: bool = arr is Array and arr.has(eval(value_expression))
	store(store_result, found)
	send_event(true_event if found else false_event)
