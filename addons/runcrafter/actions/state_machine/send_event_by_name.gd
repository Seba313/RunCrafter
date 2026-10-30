@tool
class_name RCSendEventByName
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Sends an event whose name comes from a String (bind it to a variable with the ≡ button)."

@export var event_name: String = ""
@export_enum("Self", "Other FSM", "Broadcast (all FSMs)") var send_to: int = 0
@export var target: NodePath
@export var fsm_name: String = ""
@export var delay: float = 0.0


func _on_enter() -> void:
	finish()
	if event_name.is_empty():
		return
	var sender := get_owner_node()
	match send_to:
		0:
			fsm.send_event_delayed(event_name, delay, null, sender)
		1:
			var other := RCFsmComponent.find_fsm(get_target(), fsm_name)
			if other:
				other.send_event_delayed(event_name, delay, null, sender)
		2:
			RCFsmComponent.broadcast(fsm.get_tree(), event_name, delay, null, sender)
