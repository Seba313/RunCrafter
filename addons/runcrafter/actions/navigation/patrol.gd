@tool
class_name RCPatrol
extends RCAction

const CATEGORY := "Navigation"
const DESCRIPTION := "Walks between the children of a node (waypoints) - in a loop, ping-pong or random order - with an optional wait at each point. Uses a NavigationAgent if one is found, otherwise moves straight."

## Node whose children (Node2D/Node3D) are the waypoints.
@export var waypoints: NodePath
## Moved node (empty = owner). Ignored when a NavigationAgent is found under it.
@export var target: NodePath
@export_enum("Loop", "Ping-Pong", "Random") var order: int = 0
@export var speed: float = 3.0
@export var wait_time: float = 1.0
@export var arrive_distance: float = 0.2
@export var face_direction: bool = true
@export var point_reached_event: String = ""
@export var store_point_index: String = ""

var _points: Array[Node] = []
var _index: int = 0
var _dir: int = 1
var _wait: float = 0.0
var _agent: Node


func _on_enter() -> void:
	var parent := get_optional_target("waypoints")
	_points.clear()
	if parent:
		for c in parent.get_children():
			if c is Node3D or c is Node2D:
				_points.append(c)
	if _points.is_empty():
		push_warning("RunCrafter Patrol: no waypoints (children of the Waypoints node).")
		finish()
		return
	_agent = RCNavigateTo.find_agent(self, "target")
	_wait = 0.0
	_index = clampi(_index, 0, _points.size() - 1)
	_apply_target()


func _on_physics_update(delta: float) -> void:
	if _points.is_empty():
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_next()
		return
	var p := _points[_index]
	if not is_instance_valid(p):
		return
	var reached := false
	if is_instance_valid(_agent):
		_agent.target_position = p.global_position
		reached = RCNavigateTo.step(_agent, speed, delta, face_direction)
	else:
		var n := get_target()
		if n is Node3D or n is Node2D:
			n.global_position = n.global_position.move_toward(p.global_position, speed * delta)
			reached = n.global_position.distance_to(p.global_position) <= arrive_distance
	if reached:
		store(store_point_index, _index)
		send_event(point_reached_event)
		if wait_time > 0.0:
			_wait = wait_time
		else:
			_next()


func _next() -> void:
	var count := _points.size()
	match order:
		0:
			_index = (_index + 1) % count
		1:
			if count > 1:
				if _index + _dir >= count or _index + _dir < 0:
					_dir = -_dir
				_index += _dir
		2:
			if count > 1:
				var old := _index
				while _index == old:
					_index = randi() % count
	_apply_target()


func _apply_target() -> void:
	if is_instance_valid(_agent) and is_instance_valid(_points[_index]):
		_agent.target_position = _points[_index].global_position
