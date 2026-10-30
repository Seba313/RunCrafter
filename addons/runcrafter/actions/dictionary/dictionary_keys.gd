@tool
class_name RCDictionaryKeys
extends RCAction

const CATEGORY := "Dictionary"
const DESCRIPTION := "Stores the keys, values and size of a Dictionary variable."
const TITLE := "Dictionary Keys / Values"

@export var variable: String = ""
@export var store_keys: String = ""
@export var store_values: String = ""
@export var store_count: String = ""


func _on_enter() -> void:
	finish()
	var d: Variant = get_var(variable)
	if not d is Dictionary:
		return
	store(store_keys, d.keys())
	store(store_values, d.values())
	store(store_count, d.size())
