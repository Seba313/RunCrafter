@tool
class_name RCSetText
extends RCAction

const CATEGORY := "UI"
const DESCRIPTION := "Sets the 'text' of a Label, Button, RichTextLabel, LineEdit... Use {variable} to insert values."

@export var target: NodePath
@export_multiline var text: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	if n and "text" in n:
		n.text = format_text(text)
