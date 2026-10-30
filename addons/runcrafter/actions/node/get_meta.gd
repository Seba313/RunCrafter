@tool
class_name RCGetMeta
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Reads node metadata (get_meta) into a variable."

@export var target: NodePath
@export var meta_name: String = ""
@export var store_value: String = ""
@export var missing_event: String = ""


func _on_enter() -> void:
	finish()
	var n := get_target()
	if n and n.has_meta(meta_name):
		store(store_value, n.get_meta(meta_name))
	else:
		send_event(missing_event)
