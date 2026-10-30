@tool
class_name RCSetScale3D
extends RCAction

const CATEGORY := "Transform 3D"
const DESCRIPTION := "Sets the scale of a Node3D."

@export var target: NodePath
@export var scale: Vector3 = Vector3.ONE
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target() as Node3D
	if n:
		n.scale = scale
