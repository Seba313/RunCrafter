@tool
class_name RCGetActionStrength
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Stores the strength (0..1) of an Input Map action - analog triggers and sticks."

@export var input_action: String = ""
@export var store_result: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	if InputMap.has_action(input_action):
		store(store_result, Input.get_action_strength(input_action))
