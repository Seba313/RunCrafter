@tool
class_name RCFsmControl
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Starts, stops or restarts an FSM on a node."
const TITLE := "FSM Control"

@export var target: NodePath
@export var fsm_name: String = ""
@export_enum("Start", "Stop", "Restart") var operation: int = 0


func _on_enter() -> void:
	finish()
	var other := RCFsmComponent.find_fsm(get_target(), fsm_name)
	if other == null:
		push_warning("RunCrafter FSM Control: no FSM found on target.")
		return
	match operation:
		0:
			if not other.is_running:
				other.start()
		1:
			other.stop()
		2:
			other.start()
