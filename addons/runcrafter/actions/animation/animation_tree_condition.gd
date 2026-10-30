@tool
class_name RCAnimationTreeCondition
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Sets an AnimationTree state machine condition (parameters/conditions/<name>)."
const TITLE := "AnimationTree Condition"

@export var target: NodePath
@export var condition: String = ""
@export var value: bool = true
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
		t.set("parameters/conditions/" + condition, value)
