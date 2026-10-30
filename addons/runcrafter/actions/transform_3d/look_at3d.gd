@tool
class_name RCLookAt3D
extends RCAction

const CATEGORY := "Transform 3D"
const DESCRIPTION := "Rotates a Node3D to look at a node or a position."

@export var target: NodePath
## Node to look at (empty = use Look Position).
@export var look_target: NodePath
@export var look_position: Vector3 = Vector3.ZERO
## Only rotate around the Y axis.
@export var keep_vertical: bool = true
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target() as Node3D
	if n == null:
		return
	var goal := look_position
	var lt := get_optional_target("look_target") as Node3D
	if lt:
		goal = lt.global_position
	if keep_vertical:
		goal.y = n.global_position.y
	if n.global_position.distance_squared_to(goal) > 0.000001:
		n.look_at(goal, Vector3.UP)
