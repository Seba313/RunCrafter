@tool
class_name RCCallMethod
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Calls a method on a node. Arguments are expressions (one per line)."

@export var target: NodePath
@export var method: String = ""
## One Godot Expression per line.
@export var arguments: PackedStringArray = PackedStringArray()
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	if n == null:
		return
	if not n.has_method(method):
		push_warning("RunCrafter Call Method: %s has no method '%s'." % [n.name, method])
		return
	var args: Array = []
	for a in arguments:
		args.append(eval(a))
	store(store_result, n.callv(method, args))
