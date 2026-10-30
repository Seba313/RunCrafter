@tool
class_name RCIsMultiplayerAuthority
extends RCAction

const CATEGORY := "Network"
const DESCRIPTION := "Tests whether this peer is the multiplayer authority of a node; stores the local peer id."

@export var target: NodePath
@export var true_event: String = ""
@export var false_event: String = ""
@export var store_result: String = ""
@export var store_peer_id: String = ""


func _on_enter() -> void:
	finish()
	var n := get_target()
	var r := n != null and n.is_multiplayer_authority()
	store(store_result, r)
	store(store_peer_id, n.multiplayer.get_unique_id() if n and n.multiplayer.has_multiplayer_peer() else 1)
	send_event(true_event if r else false_event)
