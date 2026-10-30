@tool
class_name RCIsOnSurface
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Tests is_on_wall() / is_on_ceiling() / is_on_floor_only() of a CharacterBody2D/3D."
const TITLE := "Is On Wall / Ceiling"

@export var target: NodePath
@export_enum("Wall", "Ceiling", "Floor Only", "Wall Only") var surface: int = 0
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
	var b := get_target()
	var r := false
	if b is CharacterBody3D or b is CharacterBody2D:
		match surface:
			0: r = b.is_on_wall()
			1: r = b.is_on_ceiling()
			2: r = b.is_on_floor_only()
			3: r = b.is_on_wall_only()
	store(store_result, r)
	send_event(true_event if r else false_event)
