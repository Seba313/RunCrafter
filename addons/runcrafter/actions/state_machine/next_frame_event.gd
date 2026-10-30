@tool
class_name RCNextFrameEvent
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Sends an event on the next frame."

@export var event: String = ""


func _on_update(_delta: float) -> void:
	finish()
	send_event(event)
