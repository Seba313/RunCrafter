@tool
class_name RCLoadSceneAsync
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Loads a scene in the background (with progress 0..1), then optionally switches to it."

@export_file("*.tscn", "*.scn") var scene_file: String = ""
@export var change_scene_when_done: bool = true
@export var store_progress: String = ""
## Stores the loaded PackedScene (Object variable).
@export var store_scene: String = ""
@export var finish_event: String = ""
@export var failed_event: String = ""


func _on_enter() -> void:
	if scene_file.is_empty() or ResourceLoader.load_threaded_request(scene_file) != OK:
		_fail()


func _on_update(_delta: float) -> void:
	var progress: Array = []
	match ResourceLoader.load_threaded_get_status(scene_file, progress):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not progress.is_empty():
				store(store_progress, float(progress[0]))
		ResourceLoader.THREAD_LOAD_LOADED:
			var ps := ResourceLoader.load_threaded_get(scene_file) as PackedScene
			store(store_progress, 1.0)
			store(store_scene, ps)
			finish()
			send_event(finish_event)
			if change_scene_when_done and ps:
				fsm.get_tree().change_scene_to_packed.call_deferred(ps)
		_:
			_fail()


func _fail() -> void:
	push_warning("RunCrafter Load Scene Async: could not load '%s'." % scene_file)
	finish()
	send_event(failed_event)
