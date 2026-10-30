@tool
class_name RCStopAnimation
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Stops an AnimationPlayer / AnimatedSprite."

@export var target: NodePath


func _on_enter() -> void:
	finish()
	var n := get_target()
	if n and n.has_method("stop"):
		n.stop()
