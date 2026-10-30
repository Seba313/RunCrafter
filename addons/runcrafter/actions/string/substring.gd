@tool
class_name RCSubstring
extends RCAction

const CATEGORY := "String"
const DESCRIPTION := "Stores a part of a string."

@export var string_value: String = ""
@export var from: int = 0
## -1 = until the end.
@export var length: int = -1
@export var store_result: String = ""


func _on_enter() -> void:
	finish()
	store(store_result, string_value.substr(from, length))
