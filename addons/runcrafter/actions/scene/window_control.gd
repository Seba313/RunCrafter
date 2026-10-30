@tool
class_name RCWindowControl
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Window and display: fullscreen, windowed, size, title, screenshot."

@export_enum("Toggle Fullscreen", "Fullscreen", "Windowed", "Set Size", "Set Title", "Screenshot") var operation: int = 0
@export var size: Vector2 = Vector2(1280, 720)
@export var title: String = ""
## Screenshot file ({time} is replaced by a timestamp).
@export var screenshot_path: String = "user://screenshot_{time}.png"
@export var store_path: String = ""


func _on_enter() -> void:
	finish()
	var win := fsm.get_window()
	match operation:
		0:
			var full := win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
			win.mode = Window.MODE_WINDOWED if full else Window.MODE_FULLSCREEN
		1:
			win.mode = Window.MODE_FULLSCREEN
		2:
			win.mode = Window.MODE_WINDOWED
		3:
			win.size = Vector2i(size)
		4:
			win.title = format_text(title)
		5:
			var path := screenshot_path.replace("{time}", Time.get_datetime_string_from_system().replace(":", "-"))
			var img := fsm.get_viewport().get_texture().get_image()
			if img and img.save_png(path) == OK:
				store(store_path, path)
