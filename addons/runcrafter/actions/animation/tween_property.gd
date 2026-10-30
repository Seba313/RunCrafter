@tool
class_name RCTweenProperty
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Tweens a property to the value of an expression (e.g. 'Vector3(0, 2, 0)' or 'Color(1, 0, 0)')."

@export var target: NodePath
## e.g. "position", "modulate", "scale:x"
@export var property: String = "position"
@export var to_expression: String = ""
@export var duration: float = 1.0
@export var delay: float = 0.0
@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var relative: bool = false
@export var wait_for_finish: bool = true
@export var kill_on_exit: bool = true
@export var finish_event: String = ""

var _tween: Tween


func _on_enter() -> void:
	var n := get_target()
	if n == null:
		finish()
		return
	var to_value: Variant = eval(to_expression)
	if to_value == null:
		push_warning("RunCrafter Tween Property: expression '%s' gave no value." % to_expression)
		finish()
		return
	_tween = n.create_tween()
	var pt := _tween.tween_property(n, NodePath(property), to_value, duration)
	pt.set_trans(transition).set_ease(ease_type).set_delay(delay)
	if relative:
		pt.as_relative()
	if wait_for_finish:
		_tween.finished.connect(_on_done)
	else:
		_on_done()


func _on_exit() -> void:
	if kill_on_exit and wait_for_finish and _tween and _tween.is_valid():
		_tween.kill()
	_tween = null


func _on_done() -> void:
	_tween = null
	finish()
	send_event(finish_event)
