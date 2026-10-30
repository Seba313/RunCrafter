@tool
class_name RCSetCollisionLayer
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Enables/disables one collision layer or mask bit (1-32) of a body or area."
const TITLE := "Set Collision Layer / Mask"

@export var target: NodePath
@export_range(1, 32) var layer_number: int = 1
@export_enum("Layer", "Mask") var which: int = 0
@export var set_enabled: bool = true


func _on_enter() -> void:
	finish()
	var n := get_target()
	if not (n is CollisionObject3D or n is CollisionObject2D):
		return
	if which == 0:
		n.set_collision_layer_value(layer_number, set_enabled)
	else:
		n.set_collision_mask_value(layer_number, set_enabled)
