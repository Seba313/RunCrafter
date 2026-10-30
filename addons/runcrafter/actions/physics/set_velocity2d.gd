@tool
class_name RCSetVelocity2D
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Sets the velocity of a CharacterBody2D or RigidBody2D."

@export var target: NodePath
@export var velocity: Vector2 = Vector2.ZERO
## Keep the current vertical (Y) velocity (gravity / jumping).
@export var keep_vertical: bool = false
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	var v := velocity
	if n is CharacterBody2D:
		if keep_vertical:
			v.y = n.velocity.y
		n.velocity = v
	elif n is RigidBody2D:
		if keep_vertical:
			v.y = n.linear_velocity.y
		n.linear_velocity = v
