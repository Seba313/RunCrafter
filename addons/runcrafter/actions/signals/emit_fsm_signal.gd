@tool
class_name RCEmitFsmSignal
extends RCAction

const CATEGORY := "Signals"
const DESCRIPTION := "Emits the custom_signal(signal_name, args) of this RCFsmComponent, so regular GDScript code can react to the FSM."
const TITLE := "Emit FSM Signal"

@export var signal_name: String = ""
## One Godot Expression per line.
@export var arguments: PackedStringArray = PackedStringArray()


func _on_enter() -> void:
	finish()
	var args: Array = []
	for a in arguments:
		args.append(eval(a))
	fsm.custom_signal.emit(signal_name, args)
