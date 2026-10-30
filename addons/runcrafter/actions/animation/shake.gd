@tool
class_name RCShake
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Shakes a node (Camera2D uses its offset, other Node2D/Node3D their position) and restores it afterwards."

@export var target: NodePath
## Pixels in 2D, meters in 3D.
@export var intensity: float = 8.0
@export var duration: float = 0.4
## The shake fades out over the duration.
@export var decay: bool = true
@export var finish_event: String = ""

var _node: Node
var _origin: Variant
var _time: float = 0.0


func _on_enter() -> void:
	_node = get_target()
	_time = 0.0
	if _node is Camera2D:
		_origin = _node.offset
	elif _node is Node2D or _node is Node3D:
		_origin = _node.position
	else:
		finish()


func _on_update(delta: float) -> void:
	_time += delta
	var k := 1.0 - clampf(_time / maxf(duration, 0.001), 0.0, 1.0) if decay else 1.0
	var a := intensity * k
	if _node is Camera2D:
		_node.offset = _origin + Vector2(randf_range(-a, a), randf_range(-a, a))
	elif _node is Node2D:
		_node.position = _origin + Vector2(randf_range(-a, a), randf_range(-a, a))
	elif _node is Node3D:
		_node.position = _origin + Vector3(randf_range(-a, a), randf_range(-a, a), randf_range(-a, a))
	if _time >= duration:
		_restore()
		finish()
		send_event(finish_event)


func _on_exit() -> void:
	_restore()


func _restore() -> void:
	if not is_instance_valid(_node) or _origin == null:
		return
	if _node is Camera2D:
		_node.offset = _origin
	else:
		_node.position = _origin
