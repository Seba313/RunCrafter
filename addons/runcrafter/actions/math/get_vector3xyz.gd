@tool
class_name RCGetVector3XYZ
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Splits a Vector3 into X, Y, Z (and length)."
const TITLE := "Get Vector3 XYZ"

@export var vector: Vector3 = Vector3.ZERO
@export var store_x: String = ""
@export var store_y: String = ""
@export var store_z: String = ""
@export var store_length: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_x, vector.x)
	store(store_y, vector.y)
	store(store_z, vector.z)
	store(store_length, vector.length())
