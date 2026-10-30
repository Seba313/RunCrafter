@tool
class_name RCRotate2D
extends RCAction

const CATEGORY := "Transform 2D"
const DESCRIPTION := "Rotates a Node2D by degrees (optionally per second)."

@export var target: NodePath
@export var degrees: float = 90.0
@export var per_second: bool = true
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
		_do(1.0)


func _on_update(delta: float) -> void:
	_do(delta if per_second else 1.0)


func _do(k: float) -> void:
	var n := get_target() as Node2D
	if n:
		n.rotation += deg_to_rad(degrees * k)
