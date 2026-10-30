@tool
class_name RCSetGravityScale
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Sets the gravity scale of a RigidBody2D/3D."

@export var target: NodePath
@export var gravity_scale: float = 1.0


func _on_enter() -> void:
	finish()
	var b := get_target()
	if b is RigidBody3D or b is RigidBody2D:
		b.gravity_scale = gravity_scale
