@tool
class_name RCGetPosition2D
extends RCAction

const CATEGORY := "Transform 2D"
const DESCRIPTION := "Stores the position of a Node2D / Control."

@export var target: NodePath
@export_enum("Local", "Global") var space: int = 1
@export var store_vector: String = ""
@export var store_x: String = ""
@export var store_y: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	if not (n is Node2D or n is Control):
		return
	var p: Vector2 = n.position if space == 0 else n.global_position
	store(store_vector, p)
	store(store_x, p.x)
	store(store_y, p.y)
