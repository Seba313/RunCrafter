@tool
class_name RCSetPosition3D
extends RCAction

const CATEGORY := "Transform 3D"
const DESCRIPTION := "Sets the position of a Node3D."

@export var target: NodePath
@export var position: Vector3 = Vector3.ZERO
@export_enum("Local", "Global") var space: int = 0
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target() as Node3D
	if n == null:
		return
	if space == 0:
		n.position = position
	else:
		n.global_position = position
