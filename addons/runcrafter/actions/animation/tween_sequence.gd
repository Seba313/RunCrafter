@tool
class_name RCTweenSequence
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Tweens several properties one after another (or in parallel). One step per line: property = expression, e.g. 'position = Vector2(100, 0)'."

@export var target: NodePath
## One step per line: "property = expression"
@export var steps: PackedStringArray = PackedStringArray()
## Duration of every step.
@export var step_duration: float = 0.5
@export var parallel: bool = false
@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var finish_event: String = ""

var _tween: Tween


func _on_enter() -> void:
	var n := get_target()
	if n == null or steps.is_empty():
		finish()
		return
	_tween = n.create_tween()
	_tween.set_parallel(parallel)
	for line in steps:
		var i := line.find("=")
		if i <= 0:
			continue
		var prop := line.substr(0, i).strip_edges()
		var value: Variant = eval(line.substr(i + 1).strip_edges())
		if value == null:
			continue
		_tween.tween_property(n, NodePath(prop), value, step_duration).set_trans(transition).set_ease(ease_type)
	_tween.finished.connect(_done)


func _on_exit() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _done() -> void:
	_tween = null
	finish()
	send_event(finish_event)
