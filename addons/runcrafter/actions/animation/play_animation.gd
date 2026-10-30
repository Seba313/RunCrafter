@tool
class_name RCPlayAnimation
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Plays an animation on an AnimationPlayer or AnimatedSprite2D/3D (target or its first AnimationPlayer child). Optionally waits until it ends."

@export var target: NodePath
@export var animation: String = ""
@export var speed: float = 1.0
## Blend time for AnimationPlayer (-1 = default).
@export var custom_blend: float = -1.0
@export var from_end: bool = false
@export var wait_for_finish: bool = false
@export var finish_event: String = ""


func _on_enter() -> void:
	var p := _find_player(get_target())
	if p == null:
		push_warning("RunCrafter Play Animation: no AnimationPlayer / AnimatedSprite found.")
		finish()
		return
	if p is AnimationPlayer:
		p.play(animation, custom_blend, speed, from_end)
		if wait_for_finish:
			connect_signal(p, &"animation_finished", _on_player_finished)
			return
	else:
		p.play(animation, speed, from_end)
		if wait_for_finish:
			connect_signal(p, &"animation_finished", _on_done)
			return
	_on_done()


func _find_player(n: Node) -> Node:
	if n == null:
		return null
	if n is AnimationPlayer or n is AnimatedSprite2D or n is AnimatedSprite3D:
		return n
	var found := n.find_children("*", "AnimationPlayer", true, false)
	if found.is_empty():
		found = n.find_children("*", "AnimatedSprite2D", true, false)
	if found.is_empty():
		found = n.find_children("*", "AnimatedSprite3D", true, false)
	return found[0] if not found.is_empty() else null


func _on_player_finished(_anim: StringName) -> void:
	_on_done()


func _on_done() -> void:
	finish()
	send_event(finish_event)
