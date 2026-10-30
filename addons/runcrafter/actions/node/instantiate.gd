@tool
class_name RCInstantiate
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Instantiates a scene, optionally at a spawn point, and stores the new node."

@export var scene: PackedScene
## Parent of the new node (empty = current scene root).
@export var parent: NodePath
## Optional node whose global transform is copied.
@export var spawn_point: NodePath
## Added to the position (Vector3 for 3D, x/y used for 2D).
@export var offset: Vector3 = Vector3.ZERO
@export var store_result: String = ""


func _on_enter() -> void:
	finish()
	if scene == null:
		return
	var p := get_optional_target("parent")
	if p == null:
		p = fsm.get_tree().current_scene
	var inst := scene.instantiate()
	p.add_child(inst)
	var sp := get_optional_target("spawn_point")
	if inst is Node3D:
		if sp is Node3D:
			inst.global_transform = sp.global_transform
		inst.global_position += offset
	elif inst is Node2D:
		if sp is Node2D:
			inst.global_transform = sp.global_transform
		inst.global_position += Vector2(offset.x, offset.y)
	store(store_result, inst)
