@tool
class_name RCDictionaryHas
extends RCAction

const CATEGORY := "Dictionary"
const DESCRIPTION := "Tests whether a Dictionary variable contains a key."

@export var variable: String = ""
@export var key: String = ""
@export var true_event: String = ""
@export var false_event: String = ""
@export var store_result: String = ""


func _on_enter() -> void:
	finish()
	var d: Variant = get_var(variable)
	var r: bool = d is Dictionary and d.has(key)
	store(store_result, r)
	send_event(true_event if r else false_event)
