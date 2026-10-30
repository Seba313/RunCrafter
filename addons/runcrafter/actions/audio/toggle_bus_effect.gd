@tool
class_name RCToggleBusEffect
extends RCAction

const CATEGORY := "Audio"
const DESCRIPTION := "Enables or disables an effect on an audio bus (e.g. underwater low-pass filter)."

@export var bus_name: String = "Master"
@export var effect_index: int = 0
@export var effect_enabled: bool = true


func _on_enter() -> void:
	finish()
	var bus := AudioServer.get_bus_index(bus_name)
	if bus >= 0 and effect_index < AudioServer.get_bus_effect_count(bus):
		AudioServer.set_bus_effect_enabled(bus, effect_index, effect_enabled)
