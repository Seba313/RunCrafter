@tool
class_name RCGetVelocity3D
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Stores the velocity (and speed) of a CharacterBody3D or RigidBody3D."

@export var target: NodePath
@export var store_vector: String = ""
@export var store_speed: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	var v := Vector3.ZERO
	if n is CharacterBody3D:
		v = n.velocity
	elif n is RigidBody3D:
		v = n.linear_velocity
	store(store_vector, v)
	store(store_speed, v.length())
