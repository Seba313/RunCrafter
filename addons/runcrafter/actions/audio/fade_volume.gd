@tool
class_name RCFadeVolume
extends RCAction

const CATEGORY := "Audio"
const DESCRIPTION := "Fades the volume of an AudioStreamPlayer (2D/3D) to a value, optionally stopping it at the end."

@export var target: NodePath
@export var to_db: float = -80.0
@export var duration: float = 1.0
@export var stop_when_done: bool = true
@export var finish_event: String = ""

var _tween: Tween


func _on_enter() -> void:
	var p := get_target()
	if not (p is AudioStreamPlayer or p is AudioStreamPlayer2D or p is AudioStreamPlayer3D):
		finish()
		return
	_tween = p.create_tween()
	_tween.tween_property(p, "volume_db", to_db, maxf(duration, 0.001))
	_tween.finished.connect(func() -> void:
		_tween = null
		if stop_when_done and is_instance_valid(p) and to_db <= -79.0:
			p.stop()
		finish()
		send_event(finish_event)
	)
