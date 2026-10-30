@tool
class_name RCScreenToWorld
extends RCAction

const CATEGORY := "Camera"
const DESCRIPTION := "Converts a screen position (or the mouse) to a world position: 3D by raycast or a horizontal plane, 2D through the canvas transform."

## Camera3D (empty = the viewport's current camera). Not needed in 2D.
@export var target: NodePath
@export var use_mouse: bool = true
@export var screen_position: Vector2 = Vector2.ZERO
@export_enum("3D Physics Raycast", "3D Plane (Y = height)", "2D") var mode: int = 0
@export var plane_height: float = 0.0
@export_flags_3d_physics var collision_mask: int = 1
@export var ray_length: float = 1000.0
@export var store_position: String = ""
@export var store_node: String = ""
@export var hit_event: String = ""
@export var no_hit_event: String = ""
@export var every_frame: bool = true


func _on_physics_update(_delta: float) -> void:
	if not every_frame:
		finish()
	var vp := fsm.get_viewport()
	var sp := vp.get_mouse_position() if use_mouse else screen_position
	if mode == 2:
		store(store_position, vp.get_canvas_transform().affine_inverse() * sp)
		send_event(hit_event)
		return
	var cam := get_optional_target("target") as Camera3D
	if cam == null:
		cam = vp.get_camera_3d()
	if cam == null:
		return
	var from := cam.project_ray_origin(sp)
	var dir := cam.project_ray_normal(sp)
	if mode == 1:
		var hit: Variant = Plane(Vector3.UP, plane_height).intersects_ray(from, dir)
		if hit == null:
			send_event(no_hit_event)
		else:
			store(store_position, hit)
			send_event(hit_event)
		return
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * ray_length, collision_mask)
	var res := cam.get_world_3d().direct_space_state.intersect_ray(q)
	if res.is_empty():
		store(store_node, null)
		send_event(no_hit_event)
	else:
		store(store_position, res.position)
		store(store_node, res.collider)
		send_event(hit_event)
