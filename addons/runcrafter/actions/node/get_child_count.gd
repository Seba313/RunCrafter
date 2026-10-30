@tool
class_name RCGetChildCount
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Stores the number of children of a node."

@export var target: NodePath
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	store(store_result, n.get_child_count() if n else 0)
