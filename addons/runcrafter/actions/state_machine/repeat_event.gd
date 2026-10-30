@tool
class_name RCRepeatEvent
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Sends an event every N seconds (optionally a limited number of times)."

@export var interval: float = 1.0
@export var event: String = ""
## 0 = repeat forever.
@export var repeat_count: int = 0
@export var send_immediately: bool = false
## Sent after the last repetition (when Repeat Count > 0).
@export var finish_event: String = ""
## By default the count survives leaving and re-entering the state (so an event that goes to
## another state and back still repeats Repeat Count times in total). It resets after the last one.
@export var reset_count_on_enter: bool = false

var _time: float = 0.0
var _count: int = 0


func _on_enter() -> void:
	_time = 0.0
	if reset_count_on_enter:
		_count = 0
	# All repetitions were sent and the last one left the state: we are back, so finish now.
	if repeat_count > 0 and _count >= repeat_count:
		_count = 0
		finish()
		send_event(finish_event)
		return
	if send_immediately:
		_fire()


func _on_update(delta: float) -> void:
	_time += delta
	if interval > 0.0 and _time >= interval:
		_time -= interval
		_fire()


func _fire() -> void:
	_count += 1
	send_event(event)
	if repeat_count > 0 and _count >= repeat_count and not fsm.is_transition_pending():
		# Still in this state after the last repetition.
		_count = 0
		finish()
		send_event(finish_event)
