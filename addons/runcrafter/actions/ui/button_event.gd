@tool
class_name RCButtonEvent
extends RCAction

const CATEGORY := "UI"
const DESCRIPTION := "Sends an event when a button is pressed / toggled."

@export var target: NodePath
@export_enum("Pressed", "Toggled On", "Toggled Off", "Button Down", "Button Up") var on: int = 0
@export var event: String = ""


func _on_enter() -> void:
	var b := get_target() as BaseButton
	if b == null:
		push_warning("RunCrafter Button Event: target is not a BaseButton.")
		return
	match on:
		0: connect_signal(b, &"pressed", _fire)
		1, 2: connect_signal(b, &"toggled", _on_toggled)
		3: connect_signal(b, &"button_down", _fire)
		4: connect_signal(b, &"button_up", _fire)


func _on_toggled(pressed: bool) -> void:
	if pressed == (on == 1):
		_fire()


func _fire() -> void:
	send_event(event)
