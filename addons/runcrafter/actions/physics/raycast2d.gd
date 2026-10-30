@tool
class_name RCRaycast2D
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Casts a ray from a Node2D and sends an event on hit / no hit."

@export var target: NodePath
## Direction * distance, in the target's local space.
@export var direction: Vector2 = Vector2(100, 0)
@export_flags_2d_physics var collision_mask: int = 1
@export var hit_event: String = ""
@export var no_hit_event: String = ""
@export var store_hit_node: String = ""
@export var store_hit_point: String = ""
@export var store_hit_normal: String = ""
@export var every_frame: bool = false


func _on_physics_update(_delta: float) -> void:
	if not every_frame:
		finish()
	var n := get_target() as Node2D
	if n == null:
		return
	var from := n.global_position
	var to := from + n.global_transform.basis_xform(direction)
	var q := PhysicsRayQueryParameters2D.create(from, to, collision_mask)
	if n is CollisionObject2D:
		q.exclude = [n.get_rid()]
	var hit := n.get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		store(store_hit_node, null)
		send_event(no_hit_event)
	else:
		store(store_hit_node, hit.collider)
		store(store_hit_point, hit.position)
		store(store_hit_normal, hit.normal)
		send_event(hit_event)
