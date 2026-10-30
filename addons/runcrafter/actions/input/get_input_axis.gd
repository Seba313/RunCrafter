@tool
class_name RCGetInputAxis
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Stores Input.get_axis(negative, positive) * multiplier."

@export var negative_input_action: String = "ui_left"
@export var positive_input_action: String = "ui_right"
@export var multiplier: float = 1.0
@export var store_result: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_result, Input.get_axis(negative_input_action, positive_input_action) * multiplier)
