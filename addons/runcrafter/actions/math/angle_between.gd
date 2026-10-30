@tool
class_name RCAngleBetween
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Angle (degrees) between two vectors. For 2D use z = 0; Signed uses the Z axis (2D) or Y axis (3D)."

@export var vector_a: Vector3 = Vector3.RIGHT
@export var vector_b: Vector3 = Vector3.FORWARD
@export var signed: bool = false
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var r := 0.0
	if signed:
		var axis := Vector3.BACK if is_zero_approx(vector_a.z) and is_zero_approx(vector_b.z) else Vector3.UP
		r = rad_to_deg(vector_a.signed_angle_to(vector_b, axis))
	else:
		r = rad_to_deg(vector_a.angle_to(vector_b))
	store(store_result, r)
