@tool
class_name RCState
extends Resource
## A single state of a [RCFsm]: a list of actions and the outgoing transitions.

@export var state_name: String = "State"
@export_multiline var description: String = ""
## Position of the state node in the graph editor.
@export var position: Vector2 = Vector2.ZERO
@export var color: Color = Color(0.25, 0.27, 0.32)
## When enabled, actions run one after another (each starts when the previous one finished)
## instead of all at once.
@export var sequence: bool = false
@export var actions: Array[RCAction] = []
@export var transitions: Array[RCTransition] = []


func get_transition(event: String) -> RCTransition:
	for t in transitions:
		if t.event == event:
			return t
	return null
