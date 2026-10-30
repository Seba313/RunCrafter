@tool
class_name RCCameraZoom
extends RCAction

const CATEGORY := "Camera"
const DESCRIPTION := "Zooms a Camera2D (zoom factor) or Camera3D (field of view), optionally smoothly."

@export var target: NodePath
## Camera2D zoom (2 = twice closer).
@export var zoom_2d: float = 1.0
## Camera3D field of view (degrees).
@export var fov_3d: float = 75.0
@export var duration: float = 0.0
@export var finish_event: String = ""

var _tween: Tween


func _on_enter() -> void:
	var c := _camera()
	if c == null:
		finish()
		return
	var prop := "zoom" if c is Camera2D else "fov"
	var value: Variant = Vector2(zoom_2d, zoom_2d) if c is Camera2D else fov_3d
	if duration <= 0.0:
		c.set(prop, value)
		_done()
		return
	_tween = c.create_tween()
	_tween.tween_property(c, prop, value, duration).set_trans(Tween.TRANS_SINE)
	_tween.finished.connect(_done)


func _on_exit() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _done() -> void:
	_tween = null
	finish()
	send_event(finish_event)


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
