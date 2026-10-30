@tool
class_name RCParticlesControl
extends RCAction

const CATEGORY := "Rendering"
const DESCRIPTION := "Starts, stops, restarts or toggles GPU/CPU particles (2D or 3D); can wait until a one-shot emission ends."

@export var target: NodePath
@export_enum("Start Emitting", "Stop Emitting", "Restart", "Toggle") var operation: int = 2
## Wait for the 'finished' signal (one-shot particles).
@export var wait_for_finish: bool = false
@export var finish_event: String = ""


func _on_enter() -> void:
	var p := get_target()
	if not (p is GPUParticles2D or p is GPUParticles3D or p is CPUParticles2D or p is CPUParticles3D):
		push_warning("RunCrafter Particles Control: target is not a particles node.")
		finish()
		return
	match operation:
		0: p.emitting = true
		1: p.emitting = false
		2: p.restart()
		3: p.emitting = not p.emitting
	if wait_for_finish and p.has_signal("finished") and p.emitting:
		connect_signal(p, &"finished", _done)
	else:
		_done()


func _done() -> void:
	finish()
	send_event(finish_event)
