@tool
class_name RCArrayForEach
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Loops over an Array variable: each time the state is entered it stores the next item and sends Loop Event; when all items were visited it sends Done Event (like PlayMaker's Array For Each)."

@export var variable: String = ""
@export var store_item: String = ""
@export var store_index: String = ""
## Sent for every item - make it lead to the states that process the item and back here.
@export var loop_event: String = ""
@export var done_event: String = ""

var _index: int = 0


func _on_enter() -> void:
	finish()
	var arr: Variant = get_var(variable)
	if arr is Array and _index < arr.size():
		store(store_item, arr[_index])
		store(store_index, _index)
		_index += 1
		send_event(loop_event)
	else:
		_index = 0
		send_event(done_event)
