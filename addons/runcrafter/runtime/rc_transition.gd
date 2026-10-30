@tool
class_name RCTransition
extends Resource
## Transition from a state (or a global transition) to [member to_state] when [member event] is received.

@export var event: String = ""
@export var to_state: String = ""


static func make(p_event: String, p_to: String = "") -> RCTransition:
	var t := RCTransition.new()
	t.event = p_event
	t.to_state = p_to
	return t
