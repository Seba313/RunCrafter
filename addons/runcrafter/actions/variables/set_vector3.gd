@tool
class_name RCSetVector3
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Sets a Vector3 variable."
const TITLE := "Set Vector3 Value"

@export var variable: String = ""
@export var value: Vector3 = Vector3.ZERO
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, value)
