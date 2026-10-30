@tool
class_name RCIsInGroup
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Tests whether a node is in a group."

@export var target: NodePath
@export var group: String = ""
@export var true_event: String = ""
@export var false_event: String = ""
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
	var r := n != null and n.is_in_group(group)
	store(store_result, r)
	send_event(true_event if r else false_event)
