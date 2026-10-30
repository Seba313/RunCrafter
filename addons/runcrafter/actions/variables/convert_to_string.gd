@tool
class_name RCConvertToString
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Converts any variable to a String (str())."

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
	store(store_result, str(get_var(variable)))
