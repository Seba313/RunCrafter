@tool
class_name RCMusicCrossfade
extends RCAction

const CATEGORY := "Audio"
const DESCRIPTION := "Crossfades from one AudioStreamPlayer to another (optionally with a new stream)."

@export var from_player: NodePath
@export var to_player: NodePath
## Optional stream for the new player.
@export var to_stream: AudioStream
@export var duration: float = 2.0
@export var target_db: float = 0.0
@export var finish_event: String = ""


func _on_enter() -> void:
	var a := get_optional_target("from_player")
	var b := get_optional_target("to_player")
	if b == null:
		finish()
		return
	if to_stream:
		b.stream = to_stream
	b.volume_db = -80.0
	b.play()
	var t := b.create_tween().set_parallel()
	t.tween_property(b, "volume_db", target_db, duration)
	if a and a != b:
		t.tween_property(a, "volume_db", -80.0, duration)
	t.finished.connect(func() -> void:
		if is_instance_valid(a) and a != b:
			a.stop()
		finish()
		send_event(finish_event)
	)
