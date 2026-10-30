@tool
class_name RCSendEvent
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Sends an event to this FSM, to an FSM on another node, or to all FSMs (broadcast). Optional delay."

@export var event: String = ""
@export_enum("Self", "Other FSM", "Broadcast (all FSMs)") var send_to: int = 0
## Node with a RCFsmComponent (or the component itself). Used when Send To = Other FSM.
@export var target: NodePath
## Optional: name of the FSM on the target node (when it has many).
@export var fsm_name: String = ""
@export var delay: float = 0.0
## Optional data sent with the event (Godot Expression, e.g. "damage" or "{'hp': hp}").
## The receiver reads it with "Get Event Info".
@export var data_expression: String = ""


func _on_enter() -> void:
	finish()
	var data: Variant = eval(data_expression) if not data_expression.is_empty() else null
	var sender := get_owner_node()
	match send_to:
		0:
			fsm.send_event_delayed(event, delay, data, sender)
		1:
			var other := RCFsmComponent.find_fsm(get_target(), fsm_name)
			if other:
				other.send_event_delayed(event, delay, data, sender)
			else:
				push_warning("RunCrafter Send Event: no FSM found on target.")
		2:
			RCFsmComponent.broadcast(fsm.get_tree(), event, delay, data, sender)
