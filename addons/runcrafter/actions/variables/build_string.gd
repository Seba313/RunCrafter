@tool
class_name RCBuildString
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Builds a string from a template (use {variable}) and stores it."

@export_multiline var text: String = ""
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_result, format_text(text))
