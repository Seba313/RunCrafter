@tool
class_name RCSetString
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Sets a String variable. Use {variable} to insert variable values."
const TITLE := "Set String Value"

@export var variable: String = ""
@export_multiline var value: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, format_text(value))
