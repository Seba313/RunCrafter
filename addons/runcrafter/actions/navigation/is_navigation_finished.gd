@tool
class_name RCIsNavigationFinished
extends RCAction

const CATEGORY := "Navigation"
const DESCRIPTION := "Tests whether a NavigationAgent2D/3D reached its target (or the target is reachable)."

@export var agent: NodePath
@export_enum("Navigation Finished", "Target Reached", "Target Reachable") var check: int = 0
@export var true_event: String = ""
@export var false_event: String = ""
@export var store_result: String = ""
@export var every_frame: bool = true


func _on_physics_update(_delta: float) -> void:
	if not every_frame:
		finish()
	var a := RCNavigateTo.find_agent(self, "agent")
	if a == null:
		return
	var r := false
	match check:
		0: r = a.is_navigation_finished()
		1: r = a.is_target_reached()
		2: r = a.is_target_reachable()
	store(store_result, r)
	send_event(true_event if r else false_event)
