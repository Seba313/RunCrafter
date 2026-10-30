@tool
class_name RCTriggerEvent
extends RCAction

const CATEGORY := "Physics"
const DESCRIPTION := "Sends an event when a body/area enters or exits an Area2D/3D (or touches a RigidBody with contact monitor)."
const TITLE := "Trigger / Contact Event"

## Area2D, Area3D, RigidBody2D or RigidBody3D (with contact_monitor enabled).
@export var target: NodePath
@export_enum("Body Entered", "Body Exited", "Area Entered", "Area Exited") var trigger: int = 0
## Only react to nodes in this group (empty = any).
@export var filter_group: String = ""
@export var event: String = ""
@export var store_other: String = ""

const SIGNALS := [&"body_entered", &"body_exited", &"area_entered", &"area_exited"]


func _on_enter() -> void:
	var n := get_target()
	if not connect_signal(n, SIGNALS[trigger], _on_trigger):
		push_warning("RunCrafter Trigger Event: target has no signal %s." % SIGNALS[trigger])


func _on_trigger(other: Node) -> void:
	if not filter_group.is_empty() and not other.is_in_group(filter_group):
		return
	store(store_other, other)
	send_event(event)
