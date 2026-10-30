@tool
class_name RCRaycast3D
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Casts a ray from a Node3D and sends an event on hit / no hit."

@export var target: NodePath
## Direction * distance, in the target's local space.
@export var direction: Vector3 = Vector3(0, 0, -10)
@export_flags_3d_physics var collision_mask: int = 1
@export var hit_event: String = ""
@export var no_hit_event: String = ""
@export var store_hit_node: String = ""
@export var store_hit_point: String = ""
@export var store_hit_normal: String = ""
@export var every_frame: bool = false


func _on_physics_update(_delta: float) -> void:
	if not every_frame:
		finish()
	var n := get_target() as Node3D
	if n == null:
		return
	var from := n.global_position
	var to := from + n.global_transform.basis * direction
	var q := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	if n is CollisionObject3D:
		q.exclude = [n.get_rid()]
	var hit := n.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		store(store_hit_node, null)
		send_event(no_hit_event)
	else:
		store(store_hit_node, hit.collider)
		store(store_hit_point, hit.position)
		store(store_hit_normal, hit.normal)
		send_event(hit_event)
