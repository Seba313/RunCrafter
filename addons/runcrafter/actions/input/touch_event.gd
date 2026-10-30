@tool
class_name RCTouchEvent
extends RCAction

const CATEGORY := "Input"
const DESCRIPTION := "Sends an event on screen touch down / up / drag and stores the position."

@export_enum("Touch Down", "Touch Up", "Drag") var trigger: int = 0
## Finger index (-1 = any).
@export var finger: int = -1
@export var event: String = ""
@export var store_position: String = ""
@export var store_relative: String = ""
@export var store_index: String = ""


func _on_input(e: InputEvent) -> void:
	var ok := false
	if e is InputEventScreenTouch:
		ok = (trigger == 0 and e.pressed) or (trigger == 1 and not e.pressed)
	elif e is InputEventScreenDrag:
		ok = trigger == 2
		if ok:
			store(store_relative, e.relative)
	if not ok or (finger >= 0 and e.index != finger):
		return
	store(store_position, e.position)
	store(store_index, e.index)
	send_event(event)
