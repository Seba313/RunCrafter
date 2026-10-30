@tool
class_name RCMoveAndSlide
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Calls move_and_slide() on a CharacterBody2D/3D every physics frame (optionally applying gravity). Never finishes."
const TITLE := "Move And Slide"

@export var target: NodePath
@export var apply_gravity: bool = true
@export var gravity_scale: float = 1.0


func _on_physics_update(delta: float) -> void:
	var n := get_target()
	if n is CharacterBody3D or n is CharacterBody2D:
		if apply_gravity and not n.is_on_floor():
			n.velocity += n.get_gravity() * gravity_scale * delta
		n.move_and_slide()
