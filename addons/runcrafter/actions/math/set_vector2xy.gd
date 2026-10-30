@tool
class_name RCSetVector2XY
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Sets selected components of a Vector2 variable."
const TITLE := "Set Vector2 XY"

@export var variable: String = ""
@export var x: float = 0.0
@export var y: float = 0.0
@export var set_x: bool = true
@export var set_y: bool = true
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var v: Vector2 = get_var(variable) if get_var(variable) is Vector2 else Vector2.ZERO
	if set_x:
		v.x = x
	if set_y:
		v.y = y
	store(variable, v)
