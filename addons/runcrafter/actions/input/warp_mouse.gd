@tool
class_name RCWarpMouse
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Moves the mouse cursor to a position in the viewport."

@export var position: Vector2 = Vector2.ZERO
## Use the center of the viewport instead of Position.
@export var center: bool = false


func _on_enter() -> void:
	finish()
	var vp := fsm.get_viewport()
	vp.warp_mouse(vp.get_visible_rect().size * 0.5 if center else position)
