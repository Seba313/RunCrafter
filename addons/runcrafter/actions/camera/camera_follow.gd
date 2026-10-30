@tool
class_name RCCameraFollow
extends RCAction

const CATEGORY := "Camera"
const DESCRIPTION := "Makes a camera (or any Node2D/3D) follow a node with smoothing and an offset. Never finishes."

## Camera (or any Node2D/Node3D) that follows.
@export var target: NodePath
@export var follow: NodePath
@export var offset: Vector3 = Vector3(0, 5, 8)
## 0 = instant, higher = faster catch-up.
@export var smoothing: float = 5.0
## Camera3D only: keep looking at the followed node.
@export var look_at_target: bool = true


func _on_update(delta: float) -> void:
	var c := get_target()
	var f := get_optional_target("follow")
	if c == null or f == null:
		return
	var k := 1.0 if smoothing <= 0.0 else 1.0 - exp(-smoothing * delta)
	if c is Node3D and f is Node3D:
		c.global_position = c.global_position.lerp(f.global_position + offset, k)
		if look_at_target and c.global_position.distance_squared_to(f.global_position) > 0.0001:
			c.look_at(f.global_position, Vector3.UP)
	elif c is Node2D and f is Node2D:
		c.global_position = c.global_position.lerp(f.global_position + Vector2(offset.x, offset.y), k)
