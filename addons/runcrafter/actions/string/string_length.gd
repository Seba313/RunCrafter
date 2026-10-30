@tool
class_name RCStringLength
extends RCAction

const CATEGORY := "String"
const DESCRIPTION := "Stores the length of a string."

@export var string_value: String = ""
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_result, string_value.length())
