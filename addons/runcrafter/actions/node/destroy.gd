@tool
class_name RCDestroy
extends RCAction

const CATEGORY := "Node"
const DESCRIPTION := "Frees a node (queue_free), optionally after a delay."
const TITLE := "Destroy Node"

@export var target: NodePath
@export var delay: float = 0.0


func _on_enter() -> void:
	finish()
	var n := get_target()
	if n == null:
		return
	if delay > 0.0:
		n.get_tree().create_timer(delay, false).timeout.connect(n.queue_free)
	else:
		n.queue_free()
