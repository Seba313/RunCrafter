@tool
class_name RCSignalCounter
extends RCAction

const CATEGORY := "Signals"
const DESCRIPTION := "Counts emissions of a signal and sends an event after N of them."

@export var target: NodePath
@export var signal_name: String = ""
@export var count: int = 3
@export var event: String = ""
@export var store_count: String = ""
## Start counting again after the event (otherwise the action finishes).
@export var repeat: bool = false

var _n: int = 0


func _on_enter() -> void:
	_n = 0
	if not connect_signal_any(get_target(), StringName(signal_name)):
		push_warning("RunCrafter Signal Counter: signal '%s' not found." % signal_name)


func _on_signal_args(_args: Array) -> void:
	if finished:
		return
	_n += 1
	store(store_count, _n)
	if _n >= count:
		_n = 0
		if not repeat:
			finish()
		send_event(event)
