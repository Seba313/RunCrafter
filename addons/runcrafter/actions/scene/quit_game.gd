@tool
class_name RCQuitGame
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Quits the game."

@export var exit_code: int = 0


func _on_enter() -> void:
	finish()
	fsm.get_tree().quit(exit_code)
