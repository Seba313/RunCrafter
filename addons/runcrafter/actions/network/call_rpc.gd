@tool
class_name RCCallRpc
extends RCAction

const CATEGORY := "Network"
const DESCRIPTION := "Calls an RPC method on a node (multiplayer). The method must have an @rpc annotation. Arguments are expressions."
const TITLE := "Call RPC"

@export var target: NodePath
@export var method: String = ""
@export var arguments: PackedStringArray = PackedStringArray()
## 0 = all peers (rpc), otherwise rpc_id(peer).
@export var peer_id: int = 0


func _on_enter() -> void:
	finish()
	var n := get_target()
	if n == null or not n.has_method(method):
		push_warning("RunCrafter Call RPC: method '%s' not found." % method)
		return
	var args: Array = []
	for a in arguments:
		args.append(eval(a))
	if peer_id == 0:
		n.callv("rpc", [StringName(method)] + args)
	else:
		n.callv("rpc_id", [peer_id, StringName(method)] + args)
