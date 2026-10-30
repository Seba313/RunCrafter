@tool
class_name RCRunFsm
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Runs another FSM (template) as a sub-state machine on the same owner and waits until it calls Finish FSM. Variables can be copied in and out."
const TITLE := "Run FSM"

@export var fsm_template: RCFsm
## Variables copied into the sub-FSM when it starts (same names must exist there).
@export var input_variables: PackedStringArray = PackedStringArray()
## Variables copied back from the sub-FSM when it finishes.
@export var output_variables: PackedStringArray = PackedStringArray()
@export var finish_event: String = ""
## Stop the sub-FSM when this state is left before it finished.
@export var stop_on_exit: bool = true

var _sub: RCFsmComponent


func _on_enter() -> void:
	if fsm_template == null:
		push_warning("RunCrafter Run FSM: no FSM template assigned.")
		finish()
		return
	_sub = RCFsmComponent.new()
	_sub.name = "SubFSM_" + fsm_template.fsm_name.validate_node_name()
	_sub.auto_start = false
	_sub.fsm = fsm_template
	_sub.log_transitions = fsm.log_transitions
	for n in input_variables:
		_sub.variable_overrides[n] = get_var(n)
	fsm.add_child(_sub, true)
	_sub.owner_path = _sub.get_path_to(fsm.get_owner_node())
	_sub.fsm_finished.connect(_on_sub_finished)
	_sub.start()


func _on_sub_finished() -> void:
	if not is_instance_valid(_sub):
		return
	for n in output_variables:
		set_var(n, _sub.get_var(n))
	_free_sub()
	finish()
	send_event(finish_event)


func _on_exit() -> void:
	if stop_on_exit:
		_free_sub()


func _free_sub() -> void:
	if is_instance_valid(_sub):
		if _sub.fsm_finished.is_connected(_on_sub_finished):
			_sub.fsm_finished.disconnect(_on_sub_finished)
		_sub.stop()
		_sub.queue_free()
	_sub = null
