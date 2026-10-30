@tool
class_name RCRandomFloat
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Stores a random float between Min and Max."

@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_result, randf_range(min_value, max_value))
