@tool
class_name RCRandomVector
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Random point inside/on a circle, sphere or box (plus a center)."

@export_enum("Inside Circle (2D)", "On Circle (2D)", "Inside Sphere (3D)", "On Sphere (3D)", "Inside Box (3D)", "Inside Rect (2D)") var mode: int = 0
@export var radius: float = 1.0
@export var box_size: Vector3 = Vector3.ONE
@export var center: Vector3 = Vector3.ZERO
@export var store_vector2: String = ""
@export var store_vector3: String = ""


func _on_enter() -> void:
	finish()
	var v := Vector3.ZERO
	match mode:
		0:
			var p := Vector2.from_angle(randf() * TAU) * sqrt(randf()) * radius
			v = Vector3(p.x, p.y, 0)
		1:
			var p := Vector2.from_angle(randf() * TAU) * radius
			v = Vector3(p.x, p.y, 0)
		2:
			v = _on_sphere() * pow(randf(), 1.0 / 3.0) * radius
		3:
			v = _on_sphere() * radius
		4:
			v = Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * box_size
		5:
			v = Vector3(randf_range(-0.5, 0.5) * box_size.x, randf_range(-0.5, 0.5) * box_size.y, 0)
	v += center
	store(store_vector2, Vector2(v.x, v.y))
	store(store_vector3, v)


func _on_sphere() -> Vector3:
	var z := randf_range(-1.0, 1.0)
	var a := randf() * TAU
	var r := sqrt(1.0 - z * z)
	return Vector3(r * cos(a), r * sin(a), z)
