@tool
class_name RCCharacterJump
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Makes a CharacterBody2D/3D jump (sets the vertical velocity), optionally only when it stands on the floor."

@export var target: NodePath
## Upward speed (positive value, works for 2D and 3D).
@export var jump_speed: float = 5.0
@export var require_floor: bool = true
@export var jumped_event: String = ""
@export var not_on_floor_event: String = ""


func _on_enter() -> void:
	finish()
	var b := get_target()
	if not (b is CharacterBody3D or b is CharacterBody2D):
		push_warning("RunCrafter Character Jump: target is not a CharacterBody.")
		return
	if require_floor and not b.is_on_floor():
		send_event(not_on_floor_event)
		return
	if b is CharacterBody3D:
		b.velocity.y = jump_speed
	else:
		b.velocity.y = -jump_speed
	send_event(jumped_event)
