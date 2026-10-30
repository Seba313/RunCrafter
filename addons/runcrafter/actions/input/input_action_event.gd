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
	store(store_result, r)
	if r:
		send_event(event)
