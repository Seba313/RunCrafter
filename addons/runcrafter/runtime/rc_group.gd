@tool
@icon("res://addons/runcrafter/icons/fsm_resource.svg")
class_name RCGroup
extends Resource
## Editor-only frame in the FSM graph. With states it is a group: a titled frame that
## wraps them and moves them together. Without states it is a free comment note.
## Ignored at runtime.

@export var title: String = ""
@export_multiline var text: String = ""
@export var color: Color = Color(0.35, 0.5, 0.7)
## Names of the grouped states (empty = comment note).
@export var states: PackedStringArray = PackedStringArray()
@export var position: Vector2 = Vector2.ZERO
@export var size: Vector2 = Vector2(260, 120)


func is_comment() -> bool:
	return states.is_empty()
