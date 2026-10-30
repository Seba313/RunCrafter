@tool
class_name RCVector2Operator
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Vector2 operations (add, subtract, scale, normalize, lerp, direction, rotate...)."

@export var vector_a: Vector2 = Vector2.ZERO
@export var vector_b: Vector2 = Vector2.ZERO
@export var scalar: float = 1.0
@export_enum("Add", "Subtract", "Multiply", "Scale A by Scalar", "Normalize A", "Rotate A (Scalar = degrees)", "Lerp (Scalar)", "Direction A to B") var operation: int = 0
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var r := Vector2.ZERO
	match operation:
		0: r = vector_a + vector_b
		1: r = vector_a - vector_b
		2: r = vector_a * vector_b
		3: r = vector_a * scalar
		4: r = vector_a.normalized()
		5: r = vector_a.rotated(deg_to_rad(scalar))
		6: r = vector_a.lerp(vector_b, scalar)
		7: r = vector_a.direction_to(vector_b)
	store(store_result, r)
