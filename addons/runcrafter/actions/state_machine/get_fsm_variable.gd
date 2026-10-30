@tool
class_name RCGetFsmVariable
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Reads a variable from an FSM on another node."
const TITLE := "Get FSM Variable"

@export var target: NodePath
@export var fsm_name: String = ""
## Name of the variable in the other FSM.
@export var remote_name: String = ""
@export var store_value: String = ""
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
		store(store_value, other.get_var(remote_name))
