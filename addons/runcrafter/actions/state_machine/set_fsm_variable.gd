@tool
class_name RCSetFsmVariable
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Writes a variable of an FSM on another node."
const TITLE := "Set FSM Variable"

@export var target: NodePath
@export var fsm_name: String = ""
## Name of the variable in the other FSM.
@export var remote_name: String = ""
## Local variable whose value is copied.
@export var source_variable: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var other := RCFsmComponent.find_fsm(get_target(), fsm_name)
	if other:
		other.set_var(remote_name, get_var(source_variable))
