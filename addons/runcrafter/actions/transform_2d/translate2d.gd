@tool
class_name RCTranslate2D
extends RCAction

const CATEGORY := "Transform 2D"
const DESCRIPTION := "Moves a Node2D by a vector (optionally per second)."

@export var target: NodePath
@export var vector: Vector2 = Vector2.ZERO
@export_enum("Self (local axes)", "World") var space: int = 1
@export var per_second: bool = true
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
		_do(1.0)


func _on_update(delta: float) -> void:
	_do(delta if per_second else 1.0)


func _do(k: float) -> void:
	var n := get_target() as Node2D
	if n == null:
		return
	if space == 0:
		n.translate(vector.rotated(n.rotation) * k)
	else:
		n.global_position += vector * k
