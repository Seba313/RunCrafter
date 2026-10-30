@tool
class_name RCRandomBool
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Stores a random bool."

@export var store_result: String = ""


func _on_enter() -> void:
	finish()
	store(store_result, randf() < 0.5)
