@tool
class_name RCRandomEvent
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Sends one of the events at random (optionally weighted)."

## One event per line.
@export var events: PackedStringArray = PackedStringArray()
## Optional weights (same count as events).
@export var weights: PackedFloat32Array = PackedFloat32Array()
@export var no_repeat: bool = false
@export var delay: float = 0.0

var _last: int = -1


func _on_enter() -> void:
	finish()
	if events.is_empty():
		return
	var idx := _pick()
	var tries := 0
	while no_repeat and events.size() > 1 and idx == _last and tries < 32:
		idx = _pick()
		tries += 1
	_last = idx
	fsm.send_event_delayed(events[idx], delay)


func _pick() -> int:
	if weights.size() != events.size():
		return randi() % events.size()
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	for i in events.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return events.size() - 1
