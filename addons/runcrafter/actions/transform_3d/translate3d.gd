@tool
class_name RCTranslate3D
extends RCAction

const CATEGORY := "Transform 3D"
const DESCRIPTION := "Moves a Node3D by a vector (optionally per second)."

@export var target: NodePath
@export var vector: Vector3 = Vector3.ZERO
@export_enum("Self (local axes)", "World") var space: int = 0
@export var per_second: bool = true
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
		_do(1.0)


func _on_update(delta: float) -> void:
	_do(delta if per_second else 1.0)


func _do(k: float) -> void:
	var n := get_target() as Node3D
	if n == null:
		return
	if space == 0:
		n.translate_object_local(vector * k)
	else:
		n.global_position += vector * k
