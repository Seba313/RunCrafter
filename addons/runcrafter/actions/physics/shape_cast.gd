@tool
class_name RCShapeCast
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Uses a ShapeCast2D/3D node: sends hit / no hit events and stores the first collider and point."
const TITLE := "Shape Cast"

@export var target: NodePath
@export var hit_event: String = ""
@export var no_hit_event: String = ""
@export var store_collider: String = ""
@export var store_point: String = ""
@export var store_count: String = ""
@export var every_frame: bool = true


func _on_physics_update(_delta: float) -> void:
	if not every_frame:
		finish()
	var sc := get_target()
	if not (sc is ShapeCast3D or sc is ShapeCast2D):
		return
	sc.force_shapecast_update()
	var count: int = sc.get_collision_count()
	store(store_count, count)
	if sc.is_colliding() and count > 0:
		store(store_collider, sc.get_collider(0))
		store(store_point, sc.get_collision_point(0))
		send_event(hit_event)
	else:
		store(store_collider, null)
		send_event(no_hit_event)
