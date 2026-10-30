@tool
class_name RCComment
extends RCAction

const CATEGORY := "Debug"
const DESCRIPTION := "Does nothing; documents the state."

@export_multiline var comment: String = ""


func _on_enter() -> void:
	finish()
