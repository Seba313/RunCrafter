@tool
class_name RCAnyKeyEvent
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Sends an event when any key, mouse button or joypad button is pressed."

@export var event: String = ""


func _on_input(e: InputEvent) -> void:
	if (e is InputEventKey or e is InputEventMouseButton or e is InputEventJoypadButton) and e.is_pressed() and not e.is_echo():
		finish()
		send_event(event)
