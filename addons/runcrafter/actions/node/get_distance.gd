@tool
class_name RCGetDistance
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Distance between two Node2D/Node3D nodes."

@export var target: NodePath
@export var other: NodePath
@export var store_result: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var a := get_target()
	var b := get_target("other")
	if a is Node3D and b is Node3D:
		store(store_result, a.global_position.distance_to(b.global_position))
	elif a is Node2D and b is Node2D:
		store(store_result, a.global_position.distance_to(b.global_position))
