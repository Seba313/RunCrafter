@tool
class_name RCAddToGroup
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Adds a node to a group (or removes it)."

@export var target: NodePath
@export var group: String = ""
@export var remove: bool = false


func _on_enter() -> void:
	finish()
	var n := get_target()
	if n == null or group.is_empty():
		return
	if remove:
		n.remove_from_group(group)
	else:
		n.add_to_group(group)
