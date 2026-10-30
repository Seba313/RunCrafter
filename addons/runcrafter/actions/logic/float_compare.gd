@tool
class_name RCFloatCompare
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Compares two floats (with tolerance) and sends an event."

@export var float_a: float = 0.0
@export var float_b: float = 0.0
@export var tolerance: float = 0.0
@export var equal_event: String = ""
@export var less_than_event: String = ""
@export var greater_than_event: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	if absf(float_a - float_b) <= tolerance:
		send_event(equal_event)
	elif float_a < float_b:
		send_event(less_than_event)
	else:
		send_event(greater_than_event)
