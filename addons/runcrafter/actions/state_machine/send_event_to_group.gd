@tool
class_name RCSendEventToGroup
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Sends an event to the FSMs of all nodes in a group (the node itself or its child RCFsmComponent)."

@export var group: String = ""
@export var event: String = ""
## Optional: only FSMs with this name.
@export var fsm_name: String = ""
@export var delay: float = 0.0
@export var include_self: bool = false
## Optional data sent with the event (Godot Expression). Read it with "Get Event Info".
@export var data_expression: String = ""


func _on_enter() -> void:
	finish()
	var data: Variant = eval(data_expression) if not data_expression.is_empty() else null
	for n in fsm.get_tree().get_nodes_in_group(group):
		var other := RCFsmComponent.find_fsm(n, fsm_name)
		if other and (include_self or other != fsm):
			other.send_event_delayed(event, delay, data, get_owner_node())
