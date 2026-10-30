@tool
class_name RCStringToNumber
extends RCAction

const CATEGORY := "String"
const DESCRIPTION := "Converts a string to an Int or Float."

@export var string_value: String = ""
@export_enum("Float", "Int") var to: int = 0
@export var store_result: String = ""
@export var invalid_event: String = ""


func _on_enter() -> void:
	finish()
	var s := string_value.strip_edges()
	if to == 0:
		if not s.is_valid_float():
			send_event(invalid_event)
			return
		store(store_result, s.to_float())
	else:
		if not s.is_valid_int():
			send_event(invalid_event)
			return
		store(store_result, s.to_int())
