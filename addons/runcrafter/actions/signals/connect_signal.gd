@tool
class_name RCConnectSignal
extends RCAction

const CATEGORY := "Signals"
const DESCRIPTION := "Permanently connects (or disconnects) a signal of one node to a method of another - independent of FSM states."
const TITLE := "Connect / Disconnect Signal"

@export var source: NodePath
@export var signal_name: String = ""
@export var target: NodePath
@export var method: String = ""
@export var disconnect_signal: bool = false
@export var one_shot: bool = false


func _on_enter() -> void:
	finish()
	var s := get_target("source")
	var t := get_target()
	if s == null or t == null or not s.has_signal(signal_name):
		push_warning("RunCrafter Connect Signal: source signal '%s' not found." % signal_name)
		return
	var c := Callable(t, method)
	if disconnect_signal:
		if s.is_connected(signal_name, c):
			s.disconnect(signal_name, c)
	elif not s.is_connected(signal_name, c):
		s.connect(signal_name, c, CONNECT_ONE_SHOT if one_shot else 0)
