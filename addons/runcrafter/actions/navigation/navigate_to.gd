@tool
class_name RCNavigateTo
extends RCAction

const CATEGORY := "Navigation"
const DESCRIPTION := "Moves the parent of a NavigationAgent2D/3D along the navigation path to a node or position, then finishes."

## NavigationAgent2D/3D (empty = first agent found under the owner).
@export var agent: NodePath
## Node to go to (empty = Goal Position).
@export var goal: NodePath
@export var goal_position: Vector3 = Vector3.ZERO
@export var speed: float = 4.0
## Re-read the goal node position every frame (follow a moving target).
@export var follow_goal: bool = true
## Rotate the body in the movement direction.
@export var face_direction: bool = true
@export var finish_event: String = ""

var _agent: Node


func _on_enter() -> void:
	_agent = RCNavigateTo.find_agent(self, "agent")
	if _agent == null:
		push_warning("RunCrafter Navigate To: no NavigationAgent2D/3D found.")
		finish()
		return
	_set_goal()


func _on_physics_update(delta: float) -> void:
	if not is_instance_valid(_agent):
		finish()
		return
	if follow_goal:
		_set_goal()
	if RCNavigateTo.step(_agent, speed, delta, face_direction):
		finish()
		send_event(finish_event)


func _on_exit() -> void:
	if is_instance_valid(_agent):
		RCNavigateTo.stop_body(_agent.get_parent())


func _set_goal() -> void:
	var g := get_optional_target("goal")
	if _agent is NavigationAgent3D:
		_agent.target_position = g.global_position if g is Node3D else goal_position
	else:
		_agent.target_position = g.global_position if g is Node2D else Vector2(goal_position.x, goal_position.y)


## Finds a NavigationAgent2D/3D on the node in [param prop] (or its descendants).
static func find_agent(action: RCAction, prop: String) -> Node:
	var n := action.get_target(prop)
	if n == null:
		return null
	if n is NavigationAgent3D or n is NavigationAgent2D:
		return n
	for t in ["NavigationAgent3D", "NavigationAgent2D"]:
		var found := n.find_children("*", t, true, false)
		if not found.is_empty():
			return found[0]
	return null


## Moves the agent's parent one step along the path. Returns true when the target is reached.
static func step(nav_agent: Node, move_speed: float, delta: float, face: bool) -> bool:
	var body = nav_agent.get_parent()
	if nav_agent.is_navigation_finished():
		stop_body(body)
		return true
	var next = nav_agent.get_next_path_position()
	if nav_agent is NavigationAgent3D:
		var to: Vector3 = next - body.global_position
		to.y = 0.0
		var vel := to.normalized() * move_speed
		if body is CharacterBody3D:
			body.velocity.x = vel.x
			body.velocity.z = vel.z
			if not body.is_on_floor():
				body.velocity += body.get_gravity() * delta
			body.move_and_slide()
		else:
			body.global_position += vel * delta
		if face and vel.length_squared() > 0.0001:
			body.look_at(body.global_position + vel, Vector3.UP)
	else:
		var vel2: Vector2 = (next - body.global_position).normalized() * move_speed
		if body is CharacterBody2D:
			body.velocity = vel2
			body.move_and_slide()
		else:
			body.global_position += vel2 * delta
		if face and vel2.length_squared() > 0.0001:
			body.rotation = vel2.angle()
	return false


static func stop_body(body: Node) -> void:
	if body is CharacterBody3D:
		body.velocity.x = 0.0
		body.velocity.z = 0.0
	elif body is CharacterBody2D:
		body.velocity = Vector2.ZERO
