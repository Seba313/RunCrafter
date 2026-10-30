@tool
class_name RCFloatSnap
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Rounds a float to a step (e.g. 0.25) or to an integer."

@export var value: float = 0.0
## 0 = round to the nearest integer.
@export var step: float = 1.0
@export_enum("Round", "Floor", "Ceil") var mode: int = 0
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var s := step if step > 0.0 else 1.0
	var k := value / s
	match mode:
		0: k = round(k)
		1: k = floor(k)
		2: k = ceil(k)
	store(store_result, k * s)
