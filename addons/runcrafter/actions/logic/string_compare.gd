@tool
class_name RCStringCompare
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Compares two strings and sends an event."

@export var string_a: String = ""
@export var string_b: String = ""
@export var ignore_case: bool = false
@export var equal_event: String = ""
@export var not_equal_event: String = ""
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var eq := string_a.nocasecmp_to(string_b) == 0 if ignore_case else string_a == string_b
	store(store_result, eq)
	send_event(equal_event if eq else not_equal_event)
