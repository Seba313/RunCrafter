@tool
class_name RCFloatInterpolate
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Interpolates a float from one value to another over time."

@export var from_value: float = 0.0
@export var to_value: float = 1.0
@export var time: float = 1.0
@export_enum("Linear", "Ease In", "Ease Out", "Ease In Out", "Smoothstep") var curve: int = 0
@export var store_result: String = ""
@export var finish_event: String = ""

var _t: float = 0.0


func _on_enter() -> void:
	_t = 0.0
	store(store_result, from_value)


func _on_update(delta: float) -> void:
	_t += delta
	var k := clampf(_t / time, 0.0, 1.0) if time > 0.0 else 1.0
	match curve:
		1: k = k * k
		2: k = 1.0 - (1.0 - k) * (1.0 - k)
		3: k = ease(k, -2.0)
		4: k = smoothstep(0.0, 1.0, k)
	store(store_result, lerpf(from_value, to_value, k))
	if _t >= time:
		finish()
		send_event(finish_event)
