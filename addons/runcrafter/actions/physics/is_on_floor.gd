@tool
class_name RCIsOnFloor
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Tests is_on_floor() of a CharacterBody2D/3D."

@export var target: NodePath
@export var true_event: String = ""
@export var false_event: String = ""
@export var store_result: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	var r := false
	if n is CharacterBody3D or n is CharacterBody2D:
		r = n.is_on_floor()
	store(store_result, r)
	send_event(true_event if r else false_event)
