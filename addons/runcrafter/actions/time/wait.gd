@tool
class_name RCWait
extends RCAction

const CATEGORY := "Time"
const DESCRIPTION := "Waits for the given time, then finishes (and sends Finish Event if set)."

@export var time: float = 1.0
@export var finish_event: String = ""
## Ignore pause and time scale.
@export var real_time: bool = false

var _elapsed: float = 0.0
var _start_ms: int = 0


func _on_enter() -> void:
	_elapsed = 0.0
	_start_ms = Time.get_ticks_msec()
	if time <= 0.0:
		_done()


func _on_update(delta: float) -> void:
	if real_time:
		_elapsed = (Time.get_ticks_msec() - _start_ms) / 1000.0
	else:
		_elapsed += delta
	if _elapsed >= time:
		_done()


func _done() -> void:
	finish()
	send_event(finish_event)
