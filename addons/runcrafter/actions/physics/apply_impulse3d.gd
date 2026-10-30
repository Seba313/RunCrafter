@tool
class_name RCApplyImpulse3D
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Applies an impulse (once) or a force (every frame) to a RigidBody3D."
const TITLE := "Apply Impulse / Force 3D"

@export var target: NodePath
@export var vector: Vector3 = Vector3(0, 5, 0)
@export_enum("Impulse", "Force (every frame)", "Torque Impulse") var mode: int = 0
@export var local_space: bool = false


func _on_enter() -> void:
	if mode != 1:
		finish()
		_do()


func _on_physics_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var b := get_target() as RigidBody3D
	if b == null:
		return
	var v := b.global_transform.basis * vector if local_space else vector
	match mode:
		0: b.apply_central_impulse(v)
		1: b.apply_central_force(v)
		2: b.apply_torque_impulse(v)
