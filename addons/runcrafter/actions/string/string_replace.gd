@tool
class_name RCStringReplace
extends RCAction

const CATEGORY := "String"
const DESCRIPTION := "Replaces text in a string."

@export var string_value: String = ""
@export var find: String = ""
@export var replace_with: String = ""
@export var ignore_case: bool = false
@export var store_result: String = ""


func _on_enter() -> void:
	finish()
	store(store_result, string_value.replacen(find, replace_with) if ignore_case else string_value.replace(find, replace_with))
