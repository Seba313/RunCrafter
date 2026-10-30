@tool
class_name RCGetInputVector
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Stores Input.get_vector(...) * multiplier (Vector2). Optionally also as Vector3 on the XZ plane."

@export var left_input_action: String = "ui_left"
@export var right_input_action: String = "ui_right"
@export var up_input_action: String = "ui_up"
@export var down_input_action: String = "ui_down"
@export var multiplier: float = 1.0
@export var store_vector2: String = ""
## Stores Vector3(x, 0, y) - handy for 3D movement.
@export var store_vector3_xz: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var v := Input.get_vector(left_input_action, right_input_action, up_input_action, down_input_action) * multiplier
	store(store_vector2, v)
	store(store_vector3_xz, Vector3(v.x, 0.0, v.y))
