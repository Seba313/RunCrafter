@tool
class_name RCRandomInt
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Stores a random integer between Min and Max (inclusive)."

@export var min_value: int = 0
@export var max_value: int = 10
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_result, randi_range(min_value, max_value))
