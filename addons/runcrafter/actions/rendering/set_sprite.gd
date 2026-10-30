@tool
class_name RCSetSprite
extends RCAction

const CATEGORY := "Rendering"
const DESCRIPTION := "Changes a Sprite2D/Sprite3D/AnimatedSprite frame, texture and flipping."

@export var target: NodePath
@export var set_frame: bool = false
@export var frame: int = 0
## Optional new texture (Sprite2D / Sprite3D).
@export var texture: Texture2D
@export_enum("Keep", "On", "Off", "Toggle") var flip_h: int = 0
@export_enum("Keep", "On", "Off", "Toggle") var flip_v: int = 0


func _on_enter() -> void:
	finish()
	var s := get_target()
	if s == null:
		return
	if set_frame and "frame" in s:
		s.frame = frame
	if texture and "texture" in s:
		s.texture = texture
	if "flip_h" in s:
		s.flip_h = _flip(s.flip_h, flip_h)
	if "flip_v" in s:
		s.flip_v = _flip(s.flip_v, flip_v)


func _flip(cur: bool, mode: int) -> bool:
	match mode:
		1: return true
		2: return false
		3: return not cur
	return cur
