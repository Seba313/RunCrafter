@tool
class_name RCIntSwitch
extends RCAction

const CATEGORY := "Logic"
const DESCRIPTION := "Sends the event matching the value (like a switch statement)."

@export var int_value: int = 0
@export var compare_to: PackedInt32Array = PackedInt32Array()
## One event per line, same order as Compare To.
@export var send_events: PackedStringArray = PackedStringArray()
@export var default_event: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	for i in mini(compare_to.size(), send_events.size()):
		if compare_to[i] == int_value:
			send_event(send_events[i])
			return
	send_event(default_event)
