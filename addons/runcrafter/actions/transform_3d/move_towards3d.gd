@tool
class_name RCMoveTowards3D
extends RCAction

const CATEGORY := "Transform 3D"
const DESCRIPTION := "Moves a Node3D towards a node or a position at a given speed."

@export var target: NodePath
## Node to move to (empty = use Goal Position).
@export var goal: NodePath
@export var goal_position: Vector3 = Vector3.ZERO
@export var speed: float = 3.0
@export var ignore_y: bool = false
@export var finish_distance: float = 0.05
@export var finish_event: String = ""


func _on_update(delta: float) -> void:
	var n := get_target() as Node3D
	if n == null:
		finish()
		return
	var g := goal_position
	var gt := get_optional_target("goal") as Node3D
	if gt:
		g = gt.global_position
	if ignore_y:
		g.y = n.global_position.y
	n.global_position = n.global_position.move_toward(g, speed * delta)
	if n.global_position.distance_to(g) <= finish_distance:
		finish()
		send_event(finish_event)
