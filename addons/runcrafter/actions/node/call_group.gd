@tool
class_name RCCallGroup
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Calls a method on every node in a group (SceneTree.call_group). Arguments are expressions, one per line."

@export var group: String = ""
@export var method: String = ""
@export var arguments: PackedStringArray = PackedStringArray()


func _on_enter() -> void:
	finish()
	var args: Array = [StringName(group), StringName(method)]
	for a in arguments:
		args.append(eval(a))
	fsm.get_tree().callv("call_group", args)
