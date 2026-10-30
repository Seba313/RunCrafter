@tool
class_name RCSetVector3XYZ
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Sets selected components of a Vector3 variable."
const TITLE := "Set Vector3 XYZ"

@export var variable: String = ""
@export var x: float = 0.0
@export var y: float = 0.0
@export var z: float = 0.0
@export var set_x: bool = true
@export var set_y: bool = true
@export var set_z: bool = true
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var v: Vector3 = get_var(variable) if get_var(variable) is Vector3 else Vector3.ZERO
	if set_x:
		v.x = x
	if set_y:
		v.y = y
	if set_z:
		v.z = z
	store(variable, v)
