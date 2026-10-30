@tool
class_name RCStringCase
extends RCAction

const CATEGORY := "String"
const DESCRIPTION := "Changes letter case / trims a string."
const TITLE := "String Case / Trim"

@export var string_value: String = ""
@export_enum("UPPER", "lower", "Capitalize", "snake_case", "camelCase", "Trim Spaces") var mode: int = 0
@export var store_result: String = ""


func _on_enter() -> void:
	finish()
	var r := string_value
	match mode:
		0: r = string_value.to_upper()
		1: r = string_value.to_lower()
		2: r = string_value.capitalize()
		3: r = string_value.to_snake_case()
		4: r = string_value.to_camel_case()
		5: r = string_value.strip_edges()
	store(store_result, r)
