@tool
class_name RCGetSlideCollision
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Reads the last collision of a CharacterBody2D/3D after move_and_slide()."

@export var target: NodePath
@export var collided_event: String = ""
@export var store_collider: String = ""
@export var store_point: String = ""
@export var store_normal: String = ""
@export var store_count: String = ""
@export var every_frame: bool = true


func _on_physics_update(_delta: float) -> void:
	if not every_frame:
		finish()
	var b := get_target()
	if not (b is CharacterBody3D or b is CharacterBody2D):
		return
	var count: int = b.get_slide_collision_count()
	store(store_count, count)
	if count == 0:
		return
	var c = b.get_last_slide_collision()
	store(store_collider, c.get_collider())
	store(store_point, c.get_position())
	store(store_normal, c.get_normal())
	send_event(collided_event)
