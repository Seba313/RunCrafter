@tool
class_name RCBoolTest
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Sends an event depending on a bool value."

@export var bool_value: bool = false
@export var is_true_event: String = ""
@export var is_false_event: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	send_event(is_true_event if bool_value else is_false_event)
