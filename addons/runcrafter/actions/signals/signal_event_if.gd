@tool
class_name RCSignalEventIf
extends RCAction

const CATEGORY := "Signals"
const DESCRIPTION := "Sends an event when a signal is emitted AND a condition is true. Signal arguments are available in the expression as arg0..arg4."
const TITLE := "Signal Event If"

@export var target: NodePath
@export var signal_name: String = ""
## e.g. "arg0 > 10" or "arg0.is_in_group('enemy')"
@export var condition: String = "true"
@export var event: String = ""
@export var else_event: String = ""
@export var store_argument: String = ""
@export var one_shot: bool = false


func _on_enter() -> void:
	if not connect_signal_any(get_target(), StringName(signal_name)):
		push_warning("RunCrafter Signal Event If: signal '%s' not found." % signal_name)


func _on_signal_args(args: Array) -> void:
	if finished:
		return
	var extra := {}
	for i in args.size():
		extra["arg%d" % i] = args[i]
	if bool(eval(condition, false, extra)):
		if not args.is_empty():
			store(store_argument, args[0])
		if one_shot:
			finish()
		send_event(event)
	else:
		send_event(else_event)
