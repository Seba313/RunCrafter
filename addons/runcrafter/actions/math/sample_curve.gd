@tool
class_name RCSampleCurve
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Samples a Curve resource at an offset (0..1) - easing, damage falloff, difficulty curves..."

@export var curve: Curve
@export var offset: float = 0.0
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	if curve:
		store(store_result, curve.sample(offset))
