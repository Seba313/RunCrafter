@tool
class_name RCGrabFocus
extends RCAction

const CATEGORY := "UI"
const DESCRIPTION := "Gives keyboard/gamepad focus to a Control (or releases it)."

@export var target: NodePath
@export var release: bool = false


func _on_enter() -> void:
	finish()
	var c := get_target() as Control
	if c:
		if release:
			c.release_focus()
		else:
			c.grab_focus()
