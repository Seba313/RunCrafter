@tool
class_name RCGetMousePosition
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Stores the mouse position in the viewport (Vector2)."

@export var store_result: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_result, fsm.get_viewport().get_mouse_position())
