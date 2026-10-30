@tool
class_name RCGetEventInfo
extends RCAction

const CATEGORY := "State Machine"
const DESCRIPTION := "Reads the event that caused the transition into this state: its name, data (from Send Event > Data Expression) and sender node."

@export var store_event: String = ""
@export var store_data: String = ""
@export var store_sender: String = ""
## If the data is a Dictionary: read this key...
@export var data_key: String = ""
## ...into this variable.
@export var store_data_field: String = ""


func _on_enter() -> void:
	finish()
	var data: Variant = fsm.state_event_data
	store(store_event, fsm.state_event)
	store(store_data, data)
	store(store_sender, fsm.state_event_sender)
	if not data_key.is_empty() and data is Dictionary and data.has(data_key):
		store(store_data_field, data[data_key])
