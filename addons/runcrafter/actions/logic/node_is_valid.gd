@tool
class_name RCNodeIsValid
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Tests whether a node (path or Object variable) exists."

@export var target: NodePath
@export var valid_event: String = ""
@export var invalid_event: String = ""
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
	var ok := n != null and is_instance_valid(n) and not n.is_queued_for_deletion()
	store(store_result, ok)
	send_event(valid_event if ok else invalid_event)
