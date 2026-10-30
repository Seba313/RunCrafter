@tool
class_name RCBoolFlip
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Inverts a Bool variable."

@export var variable: String = ""


func _on_enter() -> void:
	finish()
	store(variable, not bool(get_var(variable)))
