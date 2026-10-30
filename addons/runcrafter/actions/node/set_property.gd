@tool
class_name RCSetProperty
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Sets any property (supports sub-properties like 'position:x') to the result of an expression."

@export var target: NodePath
## e.g. "visible", "modulate", "position:y"
@export var property: String = ""
## Godot Expression, variables available by name. e.g. "speed * 2" or "Color(1, 0, 0)"
@export var value_expression: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	if n:
		n.set_indexed(NodePath(property), eval(value_expression))
