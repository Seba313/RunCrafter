@tool
class_name RCChangeScene
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Changes the current scene."

@export_file("*.tscn", "*.scn") var scene_file: String = ""


func _on_enter() -> void:
	finish()
	if not scene_file.is_empty():
		fsm.get_tree().change_scene_to_file.call_deferred(scene_file)
