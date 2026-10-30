@tool
class_name RCFreezeBody
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Freezes / unfreezes a RigidBody2D/3D (or wakes it up)."

@export var target: NodePath
@export var freeze: bool = true
@export var wake_up: bool = true


func _on_enter() -> void:
	finish()
	var b := get_target()
	if b is RigidBody3D or b is RigidBody2D:
		b.freeze = freeze
		if wake_up and not freeze:
			b.sleeping = false
