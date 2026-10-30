@tool
class_name RCSetTimeScale
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Sets Engine.time_scale (slow motion)."

@export var time_scale: float = 1.0


func _on_enter() -> void:
	finish()
	Engine.time_scale = time_scale
