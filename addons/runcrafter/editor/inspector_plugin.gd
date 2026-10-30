@tool
extends EditorInspectorPlugin
## Adds "Edit FSM in RunCrafter" buttons at the top of the Inspector for RCFsmComponent nodes
## and for nodes that have RCFsmComponent children.

const ICON := preload("res://addons/runcrafter/icons/fsm.svg")

## The RunCrafter EditorPlugin (provides open_fsm()).
var plugin: EditorPlugin


func _can_handle(object: Object) -> bool:
	return object is RCFsmComponent or (object is Node and not find_fsms(object).is_empty())


func _parse_begin(object: Object) -> void:
	var fsms: Array[RCFsmComponent] = []
	if object is RCFsmComponent:
		fsms.append(object)
	else:
		fsms = find_fsms(object)
	var box := VBoxContainer.new()
	for f in fsms:
		var b := Button.new()
		var label := f.get_fsm_name() if f.fsm else str(f.name)
		b.text = "Edit FSM '%s' in RunCrafter" % label
		b.icon = ICON
		b.pressed.connect(plugin.open_fsm.bind(f))
		box.add_child(b)
	add_custom_control(box)


## RCFsmComponent children of a node.
static func find_fsms(n: Node) -> Array[RCFsmComponent]:
	var out: Array[RCFsmComponent] = []
	for c in n.get_children():
		if c is RCFsmComponent:
			out.append(c)
	return out
