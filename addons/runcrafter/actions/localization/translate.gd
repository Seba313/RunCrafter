@tool
class_name RCTranslate
extends RCAction

const CATEGORY := "Localization"
const DESCRIPTION := "Translates a key with the project translations (tr) and stores the text."

@export var key: String = ""
@export var store_result: String = ""


func _on_enter() -> void:
	finish()
	store(store_result, fsm.tr(key))
