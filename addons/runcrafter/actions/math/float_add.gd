@tool
class_name RCFloatAdd
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Adds a value to a Float variable (optionally per second)."

@export var variable: String = ""
@export var add: float = 1.0
@export var every_frame: bool = false
## Multiply by delta time (use with Every Frame).
@export var per_second: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
		_do(fsm.get_process_delta_time())


func _on_update(delta: float) -> void:
	_do(delta)


func _do(delta: float) -> void:
	store(variable, float(get_var(variable)) + (add * delta if per_second else add))
