@tool
class_name RCSetThemeOverride
extends RCAction

const CATEGORY := "UI"
const DESCRIPTION := "Overrides a theme color, font size or constant of a Control (e.g. font_color of a Label)."

@export var target: NodePath
@export_enum("Color", "Font Size", "Constant") var override_type: int = 0
## e.g. "font_color", "font_size", "separation"
@export var item_name: String = "font_color"
@export var color: Color = Color.WHITE
@export var number: int = 16
@export var remove: bool = false


func _on_enter() -> void:
	finish()
	var c := get_target() as Control
	if c == null:
		return
	match override_type:
		0:
			if remove:
				c.remove_theme_color_override(item_name)
			else:
				c.add_theme_color_override(item_name, color)
		1:
			if remove:
				c.remove_theme_font_size_override(item_name)
			else:
				c.add_theme_font_size_override(item_name, number)
		2:
			if remove:
				c.remove_theme_constant_override(item_name)
			else:
				c.add_theme_constant_override(item_name, number)
