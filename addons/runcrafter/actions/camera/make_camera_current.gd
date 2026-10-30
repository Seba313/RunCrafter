@tool
class_name RCMakeCameraCurrent
extends RCAction

const CATEGORY := "Camera"
const DESCRIPTION := "Makes a Camera2D/3D the active camera (target or first camera under it)."

@export var target: NodePath


func _on_enter() -> void:
	finish()
	var c := _camera()
	if c:
		c.make_current()


func _camera() -> Node:
	var n := get_target()
	if n is Camera2D or n is Camera3D:
		return n
	if n:
		for t in ["Camera3D", "Camera2D"]:
			var f := n.find_children("*", t, true, false)
			if not f.is_empty():
				return f[0]
	return null
