@tool
class_name RCSetVisible
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Shows, hides or toggles a CanvasItem / Node3D."

@export var target: NodePath
@export var visible: bool = true
@export var toggle: bool = false
@export var reset_on_exit: bool = false

var _prev: bool = true
var _node: Node


func _on_enter() -> void:
	finish()
	_node = get_target()
	if _node == null or not "visible" in _node:
		return
	_prev = _node.visible
	_node.visible = (not _node.visible) if toggle else visible


func _on_exit() -> void:
	if reset_on_exit and is_instance_valid(_node) and "visible" in _node:
		_node.visible = _prev
