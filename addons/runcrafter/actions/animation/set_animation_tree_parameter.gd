@tool
class_name RCSetAnimationTreeParameter
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Sets an AnimationTree parameter (e.g. 'parameters/blend_position') to an expression."
const TITLE := "Set AnimationTree Parameter"

@export var target: NodePath
@export var parameter: String = "parameters/"
@export var value_expression: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var t := get_target() as AnimationTree
	if t:
		t.set(parameter, eval(value_expression))
