@tool
class_name RCLog
extends RCAction

const CATEGORY := "Debug"
const DESCRIPTION := "Prints a message. Use {variable} to insert variable values."

@export_multiline var text: String = ""
@export_enum("Print", "Warning", "Error") var level: int = 0
@export var include_state: bool = true


func _on_enter() -> void:
	finish()
	var msg := format_text(text)
	if include_state:
		msg = "[%s / %s] %s" % [fsm.get_owner_node().name if fsm.get_owner_node() else fsm.name, state.state_name, msg]
	match level:
		0: print(msg)
		1: push_warning(msg)
		2: push_error(msg)
