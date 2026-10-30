@tool
class_name RCFadeCanvasItem
extends RCAction

const CATEGORY := "Rendering"
const DESCRIPTION := "Fades the alpha of a CanvasItem (2D node or Control). Can show it before and hide it after the fade."
const TITLE := "Fade CanvasItem"

@export var target: NodePath
@export_range(0.0, 1.0) var to_alpha: float = 0.0
@export var duration: float = 0.5
## Start from this alpha instead of the current one (-1 = current).
@export var from_alpha: float = -1.0
@export var show_before: bool = true
## Set visible = false when the fade ends at alpha 0.
@export var hide_after: bool = false
@export var use_self_modulate: bool = false
@export var finish_event: String = ""

var _tween: Tween


func _on_enter() -> void:
	var n := get_target() as CanvasItem
	if n == null:
		finish()
		return
	var prop := "self_modulate" if use_self_modulate else "modulate"
	if from_alpha >= 0.0:
		var c: Color = n.get(prop)
		c.a = from_alpha
		n.set(prop, c)
	if show_before:
		n.visible = true
	_tween = n.create_tween()
	_tween.tween_property(n, prop + ":a", to_alpha, maxf(duration, 0.001))
	_tween.finished.connect(func() -> void:
		_tween = null
		if hide_after and is_zero_approx(to_alpha) and is_instance_valid(n):
			n.visible = false
		finish()
		send_event(finish_event)
	)


func _on_exit() -> void:
	if _tween and _tween.is_valid() and not finished:
		_tween.kill()
