@tool
class_name RCReloadScene
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Reloads the current scene."

func _on_enter() -> void:
	finish()
	fsm.get_tree().reload_current_scene.call_deferred()
