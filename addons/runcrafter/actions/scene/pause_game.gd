@tool
class_name RCPauseGame
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Pauses / unpauses the scene tree. (Set the FSM node's Process Mode to Always to keep it running while paused.)"

@export var paused: bool = true
@export var toggle: bool = false


func _on_enter() -> void:
	finish()
	var t := fsm.get_tree()
	t.paused = (not t.paused) if toggle else paused
