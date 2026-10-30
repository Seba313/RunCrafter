@tool
@icon("res://addons/runcrafter/icons/action.svg")
class_name RCAction
extends Resource
## Base class of every FSM action (the equivalent of PlayMaker's FsmStateAction).
##
## Override the virtual methods [method _on_enter], [method _on_update],
## [method _on_physics_update], [method _on_exit] and [method _on_input].
## Call [method finish] when the action is done; when every action of a state has
## finished the state sends the FINISHED event.
##
## Metadata read by the editor (declare as constants in your action script):
## [codeblock]
## const CATEGORY := "My Category"
## const DESCRIPTION := "What this action does."
## const TITLE := "Optional display name"
## [/codeblock]
## Editor conventions for exported properties:
## - [code]store_*[/code], [code]variable[/code] and [code]*_variable[/code] String properties pick an FSM variable,
## - [code]*_event[/code] String properties pick an event,
## - [code]*input_action[/code] String properties pick an Input Map action,
## - NodePath properties are relative to the FSM owner node (empty = the owner itself),
## - every other property can be bound to a variable with the "≡" button.

@export var enabled: bool = true
## Property name -> variable name. Bound properties are refreshed from variables
## before [method _on_enter] and before every update.
@export_storage var bindings: Dictionary = {}
## Editor only: whether the action is folded in the State panel.
@export_storage var editor_collapsed: bool = false

## The running state machine component (set at runtime).
var fsm: RCFsmComponent
## The state owning this action (the active state while the action runs).
## Not stored, to avoid a state <-> action reference cycle.
var state: RCState:
	get:
		return fsm.current_state if fsm else null
var finished: bool = false

var _connections: Array = []
var _node_overrides: Dictionary = {}


#region Virtual methods
func _on_enter() -> void:
	pass


func _on_update(_delta: float) -> void:
	pass


func _on_physics_update(_delta: float) -> void:
	pass


func _on_exit() -> void:
	pass


func _on_input(_event: InputEvent) -> void:
	pass
#endregion


#region Helpers for action authors
func finish() -> void:
	finished = true


## Sends an event to this FSM. [param data] can be read with the "Get Event Info" action.
func send_event(event: String, data: Variant = null) -> void:
	if fsm and not event.is_empty():
		fsm.send_event(event, data, get_owner_node())


## The node that owns the FSM (by default the parent of the RCFsmComponent).
func get_owner_node() -> Node:
	return fsm.get_owner_node() if fsm else null


## Resolves a NodePath property (or its Object variable binding) to a node.
func get_target(property: String = "target") -> Node:
	if _node_overrides.has(property):
		var n: Variant = _node_overrides[property]
		return n if n is Node and is_instance_valid(n) else null
	var path: Variant = get(property)
	var o := get_owner_node()
	if path == null or (path is NodePath and path.is_empty()):
		return o
	return o.get_node_or_null(path) if o else null


## Like [method get_target] but returns null (instead of the owner) when the path is empty
## and the property is not bound to a variable.
func get_optional_target(property: String) -> Node:
	var path: Variant = get(property)
	if not _node_overrides.has(property) and (path == null or (path is NodePath and path.is_empty())):
		return null
	return get_target(property)


func get_var(var_name: String) -> Variant:
	return fsm.get_var(var_name) if fsm else null


func set_var(var_name: String, value: Variant) -> void:
	if fsm and not var_name.is_empty():
		fsm.set_var(var_name, value)


## Stores a value in the variable named by a store_* property value.
func store(var_name: String, value: Variant) -> void:
	set_var(var_name, value)


## Evaluates a Godot [Expression]. All FSM and global variables are available by name,
## and the owner node is the base instance ([code]self[/code]).
## [param extra] adds more names, e.g. [code]{"arg0": value}[/code] (they shadow variables).
func eval(expression: String, default: Variant = null, extra: Dictionary = {}) -> Variant:
	if expression.strip_edges().is_empty():
		return default
	var names := fsm.get_all_variable_names() if fsm else PackedStringArray()
	var values: Array = []
	for n in names:
		values.append(extra[n] if extra.has(n) else fsm.get_var(n))
	for k in extra:
		if not names.has(k):
			names.append(k)
			values.append(extra[k])
	var e := Expression.new()
	if e.parse(expression, names) != OK:
		push_error("RunCrafter [%s]: %s in expression '%s'" % [get_title(), e.get_error_text(), expression])
		return default
	var r: Variant = e.execute(values, get_owner_node(), false)
	if e.has_execute_failed():
		push_error("RunCrafter [%s]: failed to execute '%s': %s" % [get_title(), expression, e.get_error_text()])
		return default
	return r


## Replaces {variable_name} placeholders with variable values.
func format_text(text: String) -> String:
	if fsm == null or not text.contains("{"):
		return text
	var d := {}
	for n in fsm.get_all_variable_names():
		d[n] = str(fsm.get_var(n))
	return text.format(d)


## Connects a signal; the connection is removed automatically when the state exits.
func connect_signal(obj: Object, sig: StringName, callable: Callable) -> bool:
	if obj == null or not obj.has_signal(sig):
		return false
	if not obj.is_connected(sig, callable):
		obj.connect(sig, callable)
		_connections.append([obj, sig, callable])
	return true


## Connects a signal with any number of arguments (0-5). The arguments are passed to
## [method _on_signal_args]. Disconnected automatically when the state exits.
func connect_signal_any(obj: Object, sig: StringName) -> bool:
	if obj == null or not obj.has_signal(sig):
		return false
	var argc := 0
	for s in obj.get_signal_list():
		if s.name == sig:
			argc = s.args.size()
			break
	var cbs := [_rc_s0, _rc_s1, _rc_s2, _rc_s3, _rc_s4, _rc_s5]
	return connect_signal(obj, sig, cbs[mini(argc, 5)])


## Called by signals connected with [method connect_signal_any].
func _on_signal_args(_args: Array) -> void:
	pass


func _rc_s0() -> void: _on_signal_args([])
func _rc_s1(a) -> void: _on_signal_args([a])
func _rc_s2(a, b) -> void: _on_signal_args([a, b])
func _rc_s3(a, b, c) -> void: _on_signal_args([a, b, c])
func _rc_s4(a, b, c, d) -> void: _on_signal_args([a, b, c, d])
func _rc_s5(a, b, c, d, e) -> void: _on_signal_args([a, b, c, d, e])


func get_title() -> String:
	return RCAction.title_for_script(get_script())
#endregion


#region Internal (called by RCFsmComponent)
func _gm_resolve_bindings() -> void:
	if bindings.is_empty():
		return
	for prop in bindings:
		var v: Variant = fsm.get_var(bindings[prop])
		var cur: Variant = get(prop)
		if cur is NodePath:
			if v is Object or v == null:
				_node_overrides[prop] = v
			else:
				_node_overrides.erase(prop)
				set(prop, NodePath(str(v)))
		elif v == null or typeof(cur) == TYPE_NIL or typeof(cur) == TYPE_OBJECT:
			set(prop, v)
		elif typeof(v) == typeof(cur):
			set(prop, v)
		else:
			set(prop, type_convert(v, typeof(cur)))


func _gm_cleanup() -> void:
	for c in _connections:
		var obj: Object = c[0]
		if is_instance_valid(obj) and obj.is_connected(c[1], c[2]):
			obj.disconnect(c[1], c[2])
	_connections.clear()
#endregion


#region Static metadata helpers
static func _const(script: Script, key: String, default: Variant) -> Variant:
	var s := script
	while s != null:
		var m := s.get_script_constant_map()
		if m.has(key):
			return m[key]
		s = s.get_base_script()
	return default


static func title_for_script(script: Script) -> String:
	if script == null:
		return "Action"
	var t: String = str(_const(script, "TITLE", ""))
	if not t.is_empty():
		return t
	var n := script.get_global_name()
	if n.is_empty():
		n = script.resource_path.get_file().get_basename()
	if n.begins_with("RC"):
		n = n.substr(2)
	n = n.capitalize()
	return n.replace(" 2d", " 2D").replace(" 3d", " 3D")


static func category_for_script(script: Script) -> String:
	return str(_const(script, "CATEGORY", "Custom"))


static func description_for_script(script: Script) -> String:
	return str(_const(script, "DESCRIPTION", ""))
#endregion
