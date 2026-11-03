@tool
class_name RCInputActionEvent
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Sends an event when an Input Map action is pressed / released."

@export var input_action: String = ""
@export_enum("Is Pressed", "Just Pressed", "Just Released", "Is Released") var check: int = 1
@export var event: String = ""
@export var store_result: String = ""
@export var every_frame: bool = true

## Frame in which this action last sent its event. "Just Pressed" stays true for
## the whole frame, so re-entering the state within the same frame must not fire
## again (otherwise State -> Event -> State loops until the per-frame limit).
var _fired_frame: int = -1


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	if input_action.is_empty() or not InputMap.has_action(input_action):
		return
	var r := false
	match check:
		0: r = Input.is_action_pressed(input_action)
		1: r = Input.is_action_just_pressed(input_action)
		2: r = Input.is_action_just_released(input_action)
		3: r = not Input.is_action_pressed(input_action)
	var frame := Engine.get_physics_frames() if Engine.is_in_physics_frame() else Engine.get_process_frames()
	if r and (check == 1 or check == 2) and frame == _fired_frame:
		r = false
	store(store_result, r)
	if r:
		_fired_frame = frame
		send_event(event)
