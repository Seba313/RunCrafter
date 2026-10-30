@tool
class_name RCSetScale2D
extends RCAction

const CATEGORY := "Transform 2D"
const DESCRIPTION := "Sets the scale of a Node2D / Control."

@export var target: NodePath
@export var scale: Vector2 = Vector2.ONE
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	if n is Node2D or n is Control:
		n.scale = scale
