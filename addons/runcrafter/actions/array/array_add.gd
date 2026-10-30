@tool
class_name RCArrayAdd
extends RCAction

const CATEGORY := "Array"
const DESCRIPTION := "Appends the result of an expression to an Array variable."

@export var variable: String = ""
@export var value_expression: String = ""


func _on_enter() -> void:
	finish()
	var arr: Variant = get_var(variable)
	if arr is Array:
		arr.append(eval(value_expression))
