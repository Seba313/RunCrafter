@tool
class_name RCAssert
extends RCAction

const CATEGORY := "Debug"
const DESCRIPTION := "Checks a condition (Godot Expression); when it is false reports an error, pauses the game or triggers a debugger breakpoint."

@export var condition: String = "true"
@export var message: String = "Assertion failed"
@export_enum("Error Message", "Pause Game", "Debugger Breakpoint") var on_fail: int = 0
@export var failed_event: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	if bool(eval(condition, false)):
		return
	var msg := "RunCrafter Assert [%s / %s]: %s (%s)" % [fsm.get_owner_node().name if fsm.get_owner_node() else fsm.name, state.state_name, format_text(message), condition]
	push_error(msg)
	match on_fail:
		1:
			fsm.get_tree().paused = true
		2:
			if OS.is_debug_build():
				breakpoint
	send_event(failed_event)
