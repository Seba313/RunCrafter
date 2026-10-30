@tool
class_name RCControlValueEvent
extends RCAction

const CATEGORY := "UI"
const DESCRIPTION := "Sends an event when the value of a control changes (Slider/SpinBox/ProgressBar, LineEdit, TextEdit, OptionButton, ItemList, CheckBox...) and stores the new value."

@export var target: NodePath
@export var event: String = ""
@export var store_value: String = ""
## LineEdit only: react on Enter (text_submitted) instead of every change.
@export var line_edit_on_submit: bool = true


func _on_enter() -> void:
	var c := get_target()
	var sig := ""
	if c is Range:
		sig = "value_changed"
	elif c is LineEdit:
		sig = "text_submitted" if line_edit_on_submit else "text_changed"
	elif c is TextEdit:
		sig = "text_changed"
	elif c is OptionButton:
		sig = "item_selected"
	elif c is ItemList:
		sig = "item_selected"
	elif c is BaseButton:
		sig = "toggled"
	if sig.is_empty() or not connect_signal_any(c, StringName(sig)):
		push_warning("RunCrafter Control Value Event: unsupported control.")


func _on_signal_args(args: Array) -> void:
	var c := get_target()
	var v: Variant = args[0] if not args.is_empty() else null
	if c is TextEdit:
		v = c.text
	store(store_value, v)
	send_event(event)
