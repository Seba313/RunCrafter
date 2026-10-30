@tool
class_name RCPlaySound
extends RCAction

const CATEGORY := "Audio"
const DESCRIPTION := "Plays an AudioStreamPlayer / 2D / 3D (optionally with another stream) and can wait for the end."

@export var target: NodePath
## Optional: stream to play instead of the player's own.
@export var stream: AudioStream
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var wait_for_finish: bool = false
@export var finish_event: String = ""


func _on_enter() -> void:
	var p := get_target()
	if not (p is AudioStreamPlayer or p is AudioStreamPlayer2D or p is AudioStreamPlayer3D):
		push_warning("RunCrafter Play Sound: target is not an AudioStreamPlayer.")
		finish()
		return
	if stream:
		p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()
	if wait_for_finish:
		connect_signal(p, &"finished", _on_done)
	else:
		_on_done()


func _on_done() -> void:
	finish()
	send_event(finish_event)
