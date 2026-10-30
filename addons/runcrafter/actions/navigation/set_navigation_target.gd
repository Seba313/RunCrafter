@tool
class_name RCSetNavigationTarget
extends RCAction

const CATEGORY := "Navigation"
const DESCRIPTION := "Sets the target position of a NavigationAgent2D/3D (without moving)."

@export var agent: NodePath
@export var goal: NodePath
@export var goal_position: Vector3 = Vector3.ZERO
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var a := RCNavigateTo.find_agent(self, "agent")
	if a == null:
		return
	var g := get_optional_target("goal")
	if a is NavigationAgent3D:
		a.target_position = g.global_position if g is Node3D else goal_position
	else:
		a.target_position = g.global_position if g is Node2D else Vector2(goal_position.x, goal_position.y)
