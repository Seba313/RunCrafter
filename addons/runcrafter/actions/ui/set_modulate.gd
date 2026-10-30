@tool
class_name RCSetModulate
extends RCAction

const CATEGORY := "UI"
const DESCRIPTION := "Sets modulate / self_modulate of a CanvasItem (2D node or Control)."

@export var target: NodePath
@export var color: Color = Color.WHITE
@export var self_modulate: bool = false
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target() as CanvasItem
	if n == null:
		return
	if self_modulate:
		n.self_modulate = color
	else:
		n.modulate = color
