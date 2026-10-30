@tool
class_name RCExpressionTest
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Evaluates a Godot Expression (variables available by name) and sends an event when true/false."

## e.g. "health <= 0 and not is_dead"
@export var expression: String = "true"
@export var true_event: String = ""
@export var false_event: String = ""
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var r := bool(eval(expression, false))
	store(store_result, r)
	send_event(true_event if r else false_event)
