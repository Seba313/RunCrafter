@tool
class_name RCMouseButtonEvent
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Sends an event when a mouse button is pressed / released."

@export var button: MouseButton = MOUSE_BUTTON_LEFT
@export_enum("Is Pressed", "Just Pressed", "Just Released") var check: int = 1
@export var event: String = ""
@export var every_frame: bool = true

var _was: bool = false


func _on_enter() -> void:
	_was = Input.is_mouse_button_pressed(button)
	if not every_frame:
		finish()
		_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var now := Input.is_mouse_button_pressed(button)
	var r := false
	match check:
		0: r = now
		1: r = now and not _was
		2: r = _was and not now
	_was = now
	if r:
		send_event(event)
