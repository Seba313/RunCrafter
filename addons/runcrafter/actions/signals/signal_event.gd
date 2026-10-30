@tool
class_name RCSignalEvent
extends RCAction

const CATEGORY := "Signals"
const DESCRIPTION := "Listens to any signal of a node and sends an event when it is emitted (like PlayMaker system events)."

@export var target: NodePath
@export var signal_name: String = ""
@export var event: String = ""
## Stores the first signal argument.
@export var store_argument: String = ""
## Stores all signal arguments as an Array.
@export var store_all_arguments: String = ""
## Finish the action after the first emission.
@export var one_shot: bool = false


func _on_enter() -> void:
	var n := get_target()
	if n == null or not n.has_signal(signal_name):
		push_warning("RunCrafter Signal Event: signal '%s' not found." % signal_name)
		return
	var argc := 0
	for s in n.get_signal_list():
		if s.name == signal_name:
			argc = s.args.size()
			break
	var cbs := [_s0, _s1, _s2, _s3, _s4, _s5]
	connect_signal(n, StringName(signal_name), cbs[mini(argc, 5)])


func _s0() -> void: _fire([])
func _s1(a) -> void: _fire([a])
func _s2(a, b) -> void: _fire([a, b])
func _s3(a, b, c) -> void: _fire([a, b, c])
func _s4(a, b, c, d) -> void: _fire([a, b, c, d])
func _s5(a, b, c, d, e) -> void: _fire([a, b, c, d, e])


func _fire(args: Array) -> void:
	if not args.is_empty():
		store(store_argument, args[0])
	store(store_all_arguments, args)
	if one_shot:
		finish()
	send_event(event)
