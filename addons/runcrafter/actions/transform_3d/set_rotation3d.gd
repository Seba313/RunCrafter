@tool
class_name RCSetRotation3D
extends RCAction

const CATEGORY := "Transform 3D"
const DESCRIPTION := "Sets the rotation (Euler degrees) of a Node3D."

@export var target: NodePath
@export var degrees: Vector3 = Vector3.ZERO
@export_enum("Local", "Global") var space: int = 0
@export var every_frame: bool = false


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
	if space == 0:
		n.rotation_degrees = degrees
	else:
		n.global_rotation_degrees = degrees
