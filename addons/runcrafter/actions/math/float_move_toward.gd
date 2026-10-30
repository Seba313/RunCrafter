@tool
class_name RCFloatMoveToward
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Moves a Float variable towards a target value at a constant speed (per second)."
const TITLE := "Float Move Toward"

@export var variable: String = ""
@export var target_value: float = 1.0
@export var speed: float = 1.0
@export var finish_event: String = ""


func _on_update(delta: float) -> void:
	var v := move_toward(float(get_var(variable)), target_value, speed * delta)
	store(variable, v)
	if is_equal_approx(v, target_value):
		finish()
		send_event(finish_event)
