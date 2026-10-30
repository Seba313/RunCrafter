@tool
class_name RCStringSplit
extends RCAction

const CATEGORY := "String"
const DESCRIPTION := "Splits a string into an Array."

@export var string_value: String = ""
@export var delimiter: String = ","
@export var allow_empty: bool = false
@export var store_array: String = ""
@export var store_count: String = ""


func _on_enter() -> void:
	finish()
	var parts := string_value.split(delimiter, allow_empty)
	store(store_array, Array(parts))
	store(store_count, parts.size())
