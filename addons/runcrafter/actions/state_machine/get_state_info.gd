@tool
class_name RCGetStateInfo
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Stores information about this FSM: current/previous state, time in state, last event."

@export var store_state_name: String = ""
@export var store_previous_state: String = ""
@export var store_state_time: String = ""
@export var store_last_event: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_state_name, fsm.get_active_state_name())
	store(store_previous_state, fsm.previous_state_name)
	store(store_state_time, fsm.state_time)
	store(store_last_event, fsm.last_event)
