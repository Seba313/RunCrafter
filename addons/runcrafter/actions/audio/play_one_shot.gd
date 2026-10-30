@tool
class_name RCPlayOneShot
extends RCAction

const CATEGORY := "Audio"
const DESCRIPTION := "Plays a sound once at a node's position without preparing an AudioStreamPlayer (a temporary player is created and freed)."
const TITLE := "Play One Shot"

@export var stream: AudioStream
## Position source (empty = owner).
@export var at: NodePath
@export_enum("Auto", "Non-positional", "2D", "3D") var positional: int = 0
@export var volume_db: float = 0.0
@export var pitch_min: float = 1.0
@export var pitch_max: float = 1.0
@export var bus: String = "Master"


func _on_enter() -> void:
	finish()
	if stream == null:
		return
	var src := get_target("at")
	var mode := positional
	if mode == 0:
		mode = 3 if src is Node3D else (2 if src is Node2D else 1)
	var p: Node
	match mode:
		2: p = AudioStreamPlayer2D.new()
		3: p = AudioStreamPlayer3D.new()
		_: p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = randf_range(minf(pitch_min, pitch_max), maxf(pitch_min, pitch_max))
	p.bus = bus
	var parent := fsm.get_tree().current_scene if fsm.get_tree().current_scene else fsm.get_tree().root
	parent.add_child(p)
	if mode == 2 and src is Node2D:
		p.global_position = src.global_position
	elif mode == 3 and src is Node3D:
		p.global_position = src.global_position
	p.finished.connect(p.queue_free)
	p.play()
