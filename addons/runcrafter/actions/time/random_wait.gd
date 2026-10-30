@tool
class_name RCRandomWait
extends RCAction

const CATEGORY := "Time"
const DESCRIPTION := "Waits for a random time between Min and Max."

@export var min_time: float = 0.5
@export var max_time: float = 2.0
@export var finish_event: String = ""

var _time: float = 0.0


func _on_enter() -> void:
	_time = randf_range(min_time, max_time)


func _on_update(delta: float) -> void:
	_time -= delta
	if _time <= 0.0:
		finish()
		send_event(finish_event)
