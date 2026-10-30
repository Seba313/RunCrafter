@tool
class_name RCDictionaryGet
extends RCAction

const CATEGORY := "Dictionary"
const DESCRIPTION := "Reads a value from a Dictionary variable."

@export var variable: String = ""
@export var key: String = ""
@export var store_value: String = ""
@export var found_event: String = ""
@export var missing_event: String = ""


func _on_enter() -> void:
	finish()
	var d: Variant = get_var(variable)
	if d is Dictionary and d.has(key):
		store(store_value, d[key])
		send_event(found_event)
	else:
		send_event(missing_event)
