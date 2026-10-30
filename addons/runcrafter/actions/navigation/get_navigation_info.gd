@tool
class_name RCGetNavigationInfo
extends RCAction

const CATEGORY := "Navigation"
const DESCRIPTION := "Stores the next path position and the distance to the target of a NavigationAgent2D/3D."

@export var agent: NodePath
@export var store_next_position: String = ""
@export var store_distance: String = ""
@export var store_final_position: String = ""
@export var every_frame: bool = true


func _on_physics_update(_delta: float) -> void:
	if not every_frame:
		finish()
	var a := RCNavigateTo.find_agent(self, "agent")
	if a == null:
		return
	store(store_next_position, a.get_next_path_position())
	store(store_distance, a.distance_to_target())
	store(store_final_position, a.get_final_position())
