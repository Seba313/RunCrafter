@tool
class_name RCGetAnimationInfo
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Stores the state of an AnimationPlayer: playing, current animation, position, length."

@export var target: NodePath
@export var store_is_playing: String = ""
@export var store_current_animation: String = ""
@export var store_position: String = ""
@export var store_length: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	var p: AnimationPlayer = n if n is AnimationPlayer else null
	if p == null and n:
		var f := n.find_children("*", "AnimationPlayer", true, false)
		if not f.is_empty():
			p = f[0]
	if p == null:
		return
	store(store_is_playing, p.is_playing())
	store(store_current_animation, String(p.current_animation))
	store(store_position, p.current_animation_position if p.is_playing() else 0.0)
	store(store_length, p.current_animation_length if p.is_playing() else 0.0)
