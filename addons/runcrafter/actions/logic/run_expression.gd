@tool
class_name RCRunExpression
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Executes a Godot Expression (e.g. calls a method on the owner) and optionally stores the result."

## e.g. "take_damage(10)" or "position.distance_to(target_pos)"
@export var expression: String = ""
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_result, eval(expression))
