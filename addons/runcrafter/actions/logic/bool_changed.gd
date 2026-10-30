@tool
class_name RCBoolChanged
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Sends an event when a (bound) bool value changes."

@export var bool_value: bool = false
@export var changed_event: String = ""

var _prev: bool = false


func _on_enter() -> void:
	_prev = bool_value


func _on_update(_delta: float) -> void:
	if bool_value != _prev:
		_prev = bool_value
		finish()
		send_event(changed_event)
