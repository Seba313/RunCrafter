@tool
class_name RCJoypadVibration
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Vibrates a gamepad."

@export var device: int = 0
@export_range(0.0, 1.0) var weak_magnitude: float = 0.5
@export_range(0.0, 1.0) var strong_magnitude: float = 0.5
## 0 = until stopped (send again with 0 magnitudes or use Stop).
@export var duration: float = 0.3
@export var stop: bool = false


func _on_enter() -> void:
	finish()
	if stop:
		Input.stop_joy_vibration(device)
	else:
		Input.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)
