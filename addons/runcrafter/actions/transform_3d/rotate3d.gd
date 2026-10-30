@tool
class_name RCRotate3D
extends RCAction

const CATEGORY := "Transform 3D"
const DESCRIPTION := "Rotates a Node3D by Euler angles in degrees (optionally per second)."

@export var target: NodePath
@export var degrees: Vector3 = Vector3(0, 90, 0)
@export_enum("Self (local axes)", "World") var space: int = 0
@export var per_second: bool = true
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
		_do(1.0)


func _on_update(delta: float) -> void:
	_do(delta if per_second else 1.0)


func _do(k: float) -> void:
	var n := get_target() as Node3D
	if n == null:
		return
	var r := degrees * k
	if space == 0:
		n.rotate_object_local(Vector3.RIGHT, deg_to_rad(r.x))
		n.rotate_object_local(Vector3.UP, deg_to_rad(r.y))
		n.rotate_object_local(Vector3.BACK, deg_to_rad(r.z))
	else:
		n.global_rotate(Vector3.RIGHT, deg_to_rad(r.x))
		n.global_rotate(Vector3.UP, deg_to_rad(r.y))
		n.global_rotate(Vector3.BACK, deg_to_rad(r.z))
