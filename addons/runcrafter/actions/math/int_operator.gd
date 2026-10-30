@tool
class_name RCIntOperator
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Performs a math operation on two integers."

@export var int_a: int = 0
@export var int_b: int = 0
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
	var r := 0
	match operation:
		0: r = int_a + int_b
		1: r = int_a - int_b
		2: r = int_a * int_b
		3: r = int_a / int_b if int_b != 0 else 0
		4: r = mini(int_a, int_b)
		5: r = maxi(int_a, int_b)
		6: r = int(pow(int_a, int_b))
		7: r = posmod(int_a, int_b) if int_b != 0 else 0
	store(store_result, r)
