@tool
class_name RCSetInt
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Sets a Int variable."
const TITLE := "Set Int Value"

@export var variable: String = ""
@export var value: int = 0
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, value)
