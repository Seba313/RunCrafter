@tool
class_name RCSetColor
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Sets a Color variable."
const TITLE := "Set Color Value"

@export var variable: String = ""
@export var value: Color = Color.WHITE
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, value)
