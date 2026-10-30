@tool
class_name RCLookAt2D
extends RCAction

const CATEGORY := "Transform 2D"
const DESCRIPTION := "Rotates a Node2D to face a node or a position."

@export var target: NodePath
## Node to look at (empty = use Look Position).
@export var look_target: NodePath
@export var look_position: Vector2 = Vector2.ZERO
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target() as Node2D
	if n == null:
		return
	var goal := look_position
	var lt := get_optional_target("look_target") as Node2D
	if lt:
		goal = lt.global_position
	n.look_at(goal)
