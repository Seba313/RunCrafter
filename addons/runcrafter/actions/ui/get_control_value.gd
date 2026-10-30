@tool
class_name RCGetControlValue
extends RCAction

const CATEGORY := "UI"
const DESCRIPTION := "Reads the value of a control: Range value, LineEdit/TextEdit text, OptionButton/ItemList selection, button pressed state."

@export var target: NodePath
@export var store_value: String = ""
## OptionButton / ItemList: text of the selected item.
@export var store_text: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var c := get_target()
	if c is Range:
		store(store_value, c.value)
	elif c is LineEdit or c is TextEdit:
		store(store_value, c.text)
		store(store_text, c.text)
	elif c is OptionButton:
		store(store_value, c.selected)
		store(store_text, c.get_item_text(c.selected) if c.selected >= 0 else "")
	elif c is ItemList:
		var sel: PackedInt32Array = c.get_selected_items()
		store(store_value, sel[0] if not sel.is_empty() else -1)
		store(store_text, c.get_item_text(sel[0]) if not sel.is_empty() else "")
	elif c is BaseButton:
		store(store_value, c.button_pressed)
