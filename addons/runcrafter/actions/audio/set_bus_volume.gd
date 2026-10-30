@tool
class_name RCSetBusVolume
extends RCAction

const CATEGORY := "Audio"
const DESCRIPTION := "Sets the volume (dB) of an audio bus."

@export var bus_name: String = "Master"
@export var volume_db: float = 0.0
@export var mute: bool = false


func _on_enter() -> void:
	finish()
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, volume_db)
		AudioServer.set_bus_mute(idx, mute)
