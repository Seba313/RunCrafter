@tool
class_name RCReparent
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Moves a node to a new parent (keeping its global transform)."
const TITLE := "Reparent Node"

@export var target: NodePath
@export var new_parent: NodePath
@export var keep_global_transform: bool = true


func _on_enter() -> void:
	finish()
	var n := get_target()
	var p := get_optional_target("new_parent")
	if n and p and n != p and not n.is_ancestor_of(p):
		n.reparent.call_deferred(p, keep_global_transform)
