@tool
class_name RCSetBool
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Sets a Bool variable."
const TITLE := "Set Bool Value"

@export var variable: String = ""
@export var value: bool = false
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, value)
