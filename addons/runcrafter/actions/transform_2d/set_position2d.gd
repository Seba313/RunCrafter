@tool
class_name RCSetPosition2D
extends RCAction

const CATEGORY := "Transform 2D"
const DESCRIPTION := "Sets the position of a Node2D / Control."

@export var target: NodePath
@export var position: Vector2 = Vector2.ZERO
@export_enum("Local", "Global") var space: int = 0
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	if n is Node2D or n is Control:
		if space == 0:
			n.position = position
		else:
			n.global_position = position
