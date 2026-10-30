@tool
class_name RCDictionaryErase
extends RCAction

const CATEGORY := "Dictionary"
const DESCRIPTION := "Removes a key (or all keys) from a Dictionary variable."

@export var variable: String = ""
@export var key: String = ""
@export var clear_all: bool = false


func _on_enter() -> void:
	finish()
	var d: Variant = get_var(variable)
	if d is Dictionary:
		if clear_all:
			d.clear()
		else:
			d.erase(key)
