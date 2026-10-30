@tool
class_name RCSetRotation2D
extends RCAction

const CATEGORY := "Transform 2D"
const DESCRIPTION := "Sets the rotation (degrees) of a Node2D."

@export var target: NodePath
@export var degrees: float = 0.0
@export_enum("Local", "Global") var space: int = 0
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target() as Node2D
	if n == null:
		return
	if space == 0:
		n.rotation_degrees = degrees
	else:
		n.global_rotation_degrees = degrees
