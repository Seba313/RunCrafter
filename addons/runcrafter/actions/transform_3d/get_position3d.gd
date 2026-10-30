@tool
class_name RCGetPosition3D
extends RCAction

const CATEGORY := "Transform 3D"
const DESCRIPTION := "Stores the position of a Node3D."

@export var target: NodePath
@export_enum("Local", "Global") var space: int = 1
@export var store_vector: String = ""
@export var store_x: String = ""
@export var store_y: String = ""
@export var store_z: String = ""
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
	var p := n.position if space == 0 else n.global_position
	store(store_vector, p)
	store(store_x, p.x)
	store(store_y, p.y)
	store(store_z, p.z)
