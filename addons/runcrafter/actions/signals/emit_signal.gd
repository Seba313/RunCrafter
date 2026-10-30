@tool
class_name RCEmitSignal
extends RCAction

const CATEGORY := "Signals"
const DESCRIPTION := "Emits a signal on a node. Arguments are expressions (one per line)."

@export var target: NodePath
@export var signal_name: String = ""
@export var arguments: PackedStringArray = PackedStringArray()


func _on_enter() -> void:
	finish()
	var n := get_target()
	if n == null or not n.has_signal(signal_name):
		push_warning("RunCrafter Emit Signal: signal '%s' not found." % signal_name)
		return
	var args: Array = [StringName(signal_name)]
	for a in arguments:
		args.append(eval(a))
	n.callv("emit_signal", args)
