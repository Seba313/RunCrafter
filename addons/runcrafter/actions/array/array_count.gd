@tool
class_name RCArrayCount
extends RCAction

const CATEGORY := "Array"
const DESCRIPTION := "Stores the size of an Array variable."

@export var variable: String = ""
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var arr: Variant = get_var(variable)
	store(store_result, arr.size() if arr is Array else 0)
