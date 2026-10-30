@tool
class_name RCAnimationTreeTravel
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Travels to a state of an AnimationTree state machine (parameters/playback)."
const TITLE := "AnimationTree Travel"

@export var target: NodePath
@export var state_name: String = ""
## Path of the playback parameter.
@export var playback_parameter: String = "parameters/playback"


func _on_enter() -> void:
	finish()
	var t := get_target() as AnimationTree
	if t == null:
		return
	var pb: Variant = t.get(playback_parameter)
	if pb is AnimationNodeStateMachinePlayback:
		pb.travel(state_name)
