@tool
class_name RCSetMeta
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Sets node metadata (set_meta) to the result of an expression."

@export var target: NodePath
@export var meta_name: String = ""
@export var value_expression: String = ""
@export var remove: bool = false


func _on_enter() -> void:
	finish()
	var n := get_target()
	if n == null or meta_name.is_empty():
		return
	if remove:
		n.remove_meta(meta_name)
	else:
		n.set_meta(meta_name, eval(value_expression))
