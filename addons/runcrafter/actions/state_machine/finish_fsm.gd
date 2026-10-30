@tool
class_name RCFinishFsm
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Stops this FSM and reports it as finished (used inside FSMs started with Run FSM)."
const TITLE := "Finish FSM"

func _on_enter() -> void:
	finish()
	fsm.finish_fsm()
