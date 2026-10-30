@tool
class_name RCKeyEvent
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Sends an event when a physical key is pressed / released."

@export var key: Key = KEY_SPACE
@export_enum("Is Pressed", "Just Pressed", "Just Released") var check: int = 1
@export var event: String = ""
@export var every_frame: bool = true

var _was: bool = false


func _on_enter() -> void:
	_was = Input.is_physical_key_pressed(key) or Input.is_key_pressed(key)
	if not every_frame:
		finish()
		_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var now := Input.is_physical_key_pressed(key) or Input.is_key_pressed(key)
	var r := false
	match check:
		0: r = now
		1: r = now and not _was
		2: r = _was and not now
	_was = now
	if r:
		send_event(event)
