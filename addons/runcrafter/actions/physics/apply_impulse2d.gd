@tool
class_name RCApplyImpulse2D
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Applies an impulse (once) or a force (every frame) to a RigidBody2D."
const TITLE := "Apply Impulse / Force 2D"

@export var target: NodePath
@export var vector: Vector2 = Vector2(0, -300)
@export_enum("Impulse", "Force (every frame)") var mode: int = 0


func _on_enter() -> void:
	if mode == 0:
		finish()
		_do()


func _on_physics_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var b := get_target() as RigidBody2D
	if b == null:
		return
	if mode == 0:
		b.apply_central_impulse(vector)
	else:
		b.apply_central_force(vector)
