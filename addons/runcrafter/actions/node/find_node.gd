@tool
class_name RCFindNode
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Finds a node by path, by group or by name and stores it in an Object variable."

@export_enum("By Path", "First In Group", "By Name (recursive)") var mode: int = 0
@export var path: NodePath
@export var group: String = ""
@export var node_name: String = ""
@export var store_result: String = ""
@export var found_event: String = ""
@export var not_found_event: String = ""


func _on_enter() -> void:
	finish()
	var n: Node = null
	match mode:
		0:
			n = get_target("path")
		1:
			n = fsm.get_tree().get_first_node_in_group(group)
		2:
			n = fsm.get_tree().root.find_child(node_name, true, false)
	store(store_result, n)
	send_event(found_event if n else not_found_event)
