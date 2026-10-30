@tool
class_name RCFloatRemap
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Remaps a value from one range to another (e.g. 0..100 HP -> 0..1)."

@export var value: float = 0.0
@export var in_min: float = 0.0
@export var in_max: float = 1.0
@export var out_min: float = 0.0
@export var out_max: float = 1.0
@export var clamp_result: bool = true
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var r := remap(value, in_min, in_max, out_min, out_max) if not is_equal_approx(in_min, in_max) else out_min
	if clamp_result:
		r = clampf(r, minf(out_min, out_max), maxf(out_min, out_max))
	store(store_result, r)
