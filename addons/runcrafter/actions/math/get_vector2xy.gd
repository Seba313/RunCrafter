@tool
class_name RCGetVector2XY
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Splits a Vector2 into X, Y (and length)."
const TITLE := "Get Vector2 XY"

@export var vector: Vector2 = Vector2.ZERO
@export var store_x: String = ""
@export var store_y: String = ""
@export var store_length: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	store(store_x, vector.x)
	store(store_y, vector.y)
	store(store_length, vector.length())
