@tool
class_name RCSetProcessMode
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Sets the process mode of a node (e.g. Always to keep running while paused, Disabled to freeze it)."

@export var target: NodePath
@export var process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT


func _on_enter() -> void:
	finish()
	var n := get_target()
	if n:
		n.process_mode = process_mode
