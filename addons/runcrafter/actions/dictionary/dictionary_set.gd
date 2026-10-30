@tool
class_name RCDictionarySet
extends RCAction

const CATEGORY := "Dictionary"
const DESCRIPTION := "Sets a key of a Dictionary variable to the result of an expression."

@export var variable: String = ""
@export var key: String = ""
## Godot Expression, e.g. "score + 1" or "'text'"
@export var value_expression: String = ""


func _on_enter() -> void:
	finish()
	var d: Variant = get_var(variable)
	if d is Dictionary:
		d[key] = eval(value_expression)
