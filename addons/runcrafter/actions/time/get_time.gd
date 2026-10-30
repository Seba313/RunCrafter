@tool
class_name RCGetTime
extends RCAction

const CATEGORY := "Time"
const DESCRIPTION := "Stores the time since the game started (seconds) and/or the frame delta."

@export var store_time: String = ""
@export var store_delta: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do(fsm.get_process_delta_time())


func _on_update(delta: float) -> void:
	_do(delta)


func _do(delta: float) -> void:
	store(store_time, Time.get_ticks_msec() / 1000.0)
	store(store_delta, delta)
