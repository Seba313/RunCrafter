@tool
class_name RCAnimationPlayerControl
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Controls an AnimationPlayer: queue, seek, speed, pause, resume, stop."
const TITLE := "AnimationPlayer Control"

@export var target: NodePath
@export_enum("Queue Animation", "Seek (seconds)", "Set Speed Scale", "Pause", "Resume", "Stop") var operation: int = 0
@export var animation: String = ""
@export var seconds: float = 0.0
@export var speed_scale: float = 1.0


func _on_enter() -> void:
	finish()
	var p := _player()
	if p == null:
		push_warning("RunCrafter AnimationPlayer Control: no AnimationPlayer found.")
		return
	match operation:
		0: p.queue(animation)
		1: p.seek(seconds, true)
		2: p.speed_scale = speed_scale
		3: p.pause()
		4: p.play()
		5: p.stop()


func _player() -> AnimationPlayer:
	var n := get_target()
	if n is AnimationPlayer:
		return n
	if n:
		var f := n.find_children("*", "AnimationPlayer", true, false)
		if not f.is_empty():
			return f[0]
	return null
