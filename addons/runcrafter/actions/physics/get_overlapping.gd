@tool
class_name RCGetOverlapping
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Stores the bodies or areas currently inside an Area2D/3D (optionally only nodes in a group)."
const TITLE := "Get Overlapping Bodies / Areas"

@export var target: NodePath
@export_enum("Bodies", "Areas") var mode: int = 0
@export var filter_group: String = ""
@export var store_array: String = ""
@export var store_count: String = ""
@export var store_first: String = ""
@export var any_event: String = ""
@export var none_event: String = ""
@export var every_frame: bool = false


func _on_physics_update(_delta: float) -> void:
	if not every_frame:
		finish()
	var a := get_target()
	if not (a is Area3D or a is Area2D):
		return
	var list: Array = a.get_overlapping_bodies() if mode == 0 else a.get_overlapping_areas()
	if not filter_group.is_empty():
		list = list.filter(func(n: Node) -> bool: return n.is_in_group(filter_group))
	store(store_array, list)
	store(store_count, list.size())
	store(store_first, list[0] if not list.is_empty() else null)
	send_event(any_event if not list.is_empty() else none_event)
