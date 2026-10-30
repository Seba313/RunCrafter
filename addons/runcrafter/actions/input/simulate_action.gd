@tool
class_name RCSimulateAction
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Presses / releases an Input Map action from the FSM (e.g. AI that drives the same logic as the player)."

@export var input_action: String = ""
@export_enum("Press", "Release", "Tap - press and release next frame") var mode: int = 2
@export_range(0.0, 1.0) var strength: float = 1.0


func _on_enter() -> void:
	if not InputMap.has_action(input_action):
		finish()
		return
	match mode:
		0:
			Input.action_press(input_action, strength)
			finish()
		1:
			Input.action_release(input_action)
			finish()
		2:
			Input.action_press(input_action, strength)


func _on_update(_delta: float) -> void:
	Input.action_release(input_action)
	finish()


func _on_exit() -> void:
	if mode == 2 and not finished:
		Input.action_release(input_action)
