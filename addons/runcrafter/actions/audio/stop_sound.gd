@tool
class_name RCStopSound
extends RCAction

const CATEGORY := "Audio"
const DESCRIPTION := "Stops an AudioStreamPlayer / 2D / 3D."

@export var target: NodePath


func _on_enter() -> void:
	finish()
	var p := get_target()
	if p and p.has_method("stop"):
		p.stop()
