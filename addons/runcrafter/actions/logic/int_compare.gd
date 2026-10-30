@tool
class_name RCIntCompare
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Compares two integers and sends an event."

@export var int_a: int = 0
@export var int_b: int = 0
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
	if int_a == int_b:
		send_event(equal_event)
	elif int_a < int_b:
		send_event(less_than_event)
	else:
		send_event(greater_than_event)
