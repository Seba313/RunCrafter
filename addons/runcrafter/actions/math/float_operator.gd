@tool
class_name RCFloatOperator
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Performs a math operation on two floats."

@export var float_a: float = 0.0
@export var float_b: float = 0.0
@export_enum("Add", "Subtract", "Multiply", "Divide", "Min", "Max", "Power", "Modulo") var operation: int = 0
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var r := 0.0
	match operation:
		0: r = float_a + float_b
		1: r = float_a - float_b
		2: r = float_a * float_b
		3: r = float_a / float_b if float_b != 0.0 else 0.0
		4: r = minf(float_a, float_b)
		5: r = maxf(float_a, float_b)
		6: r = pow(float_a, float_b)
		7: r = fmod(float_a, float_b) if float_b != 0.0 else 0.0
	store(store_result, r)
