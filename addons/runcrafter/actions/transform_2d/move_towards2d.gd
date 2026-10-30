@tool
class_name RCMoveTowards2D
extends RCAction

const CATEGORY := "Transform 2D"
const DESCRIPTION := "Moves a Node2D towards a node or a position at a given speed."

@export var target: NodePath
## Node to move to (empty = use Goal Position).
@export var goal: NodePath
@export var goal_position: Vector2 = Vector2.ZERO
@export var speed: float = 200.0
@export var finish_distance: float = 1.0
@export var finish_event: String = ""


func _on_update(delta: float) -> void:
	var n := get_target() as Node2D
	if n == null:
		finish()
		return
	var g := goal_position
	var gt := get_optional_target("goal") as Node2D
	if gt:
		g = gt.global_position
	n.global_position = n.global_position.move_toward(g, speed * delta)
	if n.global_position.distance_to(g) <= finish_distance:
		finish()
		send_event(finish_event)
