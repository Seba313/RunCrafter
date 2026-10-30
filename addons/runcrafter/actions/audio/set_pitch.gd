@tool
class_name RCSetPitch
extends RCAction

const CATEGORY := "Audio"
const DESCRIPTION := "Sets the pitch of an AudioStreamPlayer (2D/3D), optionally randomized."

@export var target: NodePath
@export var pitch: float = 1.0
## Random +/- added to the pitch.
@export var random_range: float = 0.0


func _on_enter() -> void:
	finish()
	var p := get_target()
	if p and "pitch_scale" in p:
		p.pitch_scale = maxf(0.01, pitch + randf_range(-random_range, random_range))
