@tool
class_name RCSetVariableExpression
extends RCAction

const CATEGORY := "Variables"
const DESCRIPTION := "Sets any variable to the result of a Godot Expression, e.g. 'speed * 2.0' or 'Vector3(0, 1, 0)'."
const TITLE := "Set Variable (Expression)"

@export var variable: String = ""
@export var expression: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(variable, eval(expression))
