@tool
class_name RCWaitForSignal
extends RCAction

const CATEGORY := "Signals"
const DESCRIPTION := "Waits until a node emits a signal, then finishes (optionally with a timeout)."

@export var target: NodePath
@export var signal_name: String = ""
@export var finish_event: String = ""
## Seconds (0 = wait forever).
@export var timeout: float = 0.0
@export var timeout_event: String = ""
## Stores the first signal argument.
@export var store_argument: String = ""

var _time: float = 0.0


func _on_enter() -> void:
	_time = 0.0
	if not connect_signal_any(get_target(), StringName(signal_name)):
		push_warning("RunCrafter Wait For Signal: signal '%s' not found." % signal_name)
		finish()


func _on_update(delta: float) -> void:
	if timeout <= 0.0:
		return
	_time += delta
	if _time >= timeout:
		finish()
		send_event(timeout_event)


func _on_signal_args(args: Array) -> void:
	if finished:
		return
	if not args.is_empty():
		store(store_argument, args[0])
	finish()
	send_event(finish_event)
