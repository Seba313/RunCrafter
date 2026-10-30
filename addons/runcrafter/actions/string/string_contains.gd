@tool
class_name RCStringContains
extends RCAction

const CATEGORY := "String"
const DESCRIPTION := "Tests whether a string contains / starts with / ends with a text."

@export var string_value: String = ""
@export var text: String = ""
@export_enum("Contains", "Starts With", "Ends With") var mode: int = 0
@export var ignore_case: bool = false
@export var true_event: String = ""
@export var false_event: String = ""
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var a := string_value.to_lower() if ignore_case else string_value
	var b := text.to_lower() if ignore_case else text
	var r := false
	match mode:
		0: r = a.contains(b)
		1: r = a.begins_with(b)
		2: r = a.ends_with(b)
	store(store_result, r)
	send_event(true_event if r else false_event)
