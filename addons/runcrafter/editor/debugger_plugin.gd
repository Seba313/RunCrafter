@tool
extends EditorDebuggerPlugin
## Receives state changes from running games and forwards them to the FSM editor
## (live highlighting of the active state + transition log).

var editor: Object


func _has_capture(capture: String) -> bool:
	return capture == "runcrafter"


func _capture(message: String, data: Array, _session_id: int) -> bool:
	if message == "runcrafter:state" and editor:
		editor.on_debug_state(data)
		return true
	return false


func _setup_session(session_id: int) -> void:
	var s := get_session(session_id)
	if s:
		s.stopped.connect(func() -> void:
			if editor:
				editor.on_debug_stopped()
		)
