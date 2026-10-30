@tool
class_name RCSetVector2
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Sets a Vector2 variable."
const TITLE := "Set Vector2 Value"

@export var variable: String = ""
@export var value: Vector2 = Vector2.ZERO
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, value)
