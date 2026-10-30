@tool
class_name RCGetProperty
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Reads any property (supports 'position:x') into a variable."

@export var target: NodePath
@export var property: String = ""
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
	if n:
		store(store_result, n.get_indexed(NodePath(property)))
