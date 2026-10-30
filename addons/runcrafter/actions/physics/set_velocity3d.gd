@tool
class_name RCSetVelocity3D
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Sets the velocity of a CharacterBody3D or RigidBody3D."

@export var target: NodePath
@export var velocity: Vector3 = Vector3.ZERO
@export_enum("World", "Self (local axes)") var space: int = 0
## Keep the current vertical (Y) velocity (gravity / jumping).
@export var keep_vertical: bool = false
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	var v := velocity
	if space == 1 and n is Node3D:
		v = n.global_transform.basis * v
	if n is CharacterBody3D:
		if keep_vertical:
			v.y = n.velocity.y
		n.velocity = v
	elif n is RigidBody3D:
		if keep_vertical:
			v.y = n.linear_velocity.y
		n.linear_velocity = v
