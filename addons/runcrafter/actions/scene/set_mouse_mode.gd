@tool
class_name RCSetMouseMode
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Sets the mouse mode (visible, captured, hidden...)."

@export var mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE


func _on_enter() -> void:
	finish()
	Input.mouse_mode = mouse_mode
