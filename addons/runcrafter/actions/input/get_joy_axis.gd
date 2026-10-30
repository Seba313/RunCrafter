@tool
class_name RCGetJoyAxis
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Stores the value (-1..1) of a gamepad axis."
const TITLE := "Get Joy Axis"

@export var device: int = 0
@export var axis: JoyAxis = JOY_AXIS_LEFT_X
@export var deadzone: float = 0.2
@export var store_result: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var v := Input.get_joy_axis(device, axis)
	store(store_result, 0.0 if absf(v) < deadzone else v)
