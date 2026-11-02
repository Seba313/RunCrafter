@tool
@icon("res://addons/runcrafter/icons/fsm_resource.svg")
class_name RCFsm
extends Resource
## Finite State Machine asset. Can be embedded in a [RCFsmComponent] or saved as a
## .tres file and shared between many components (a "template").

const FINISHED := "FINISHED"

@export var fsm_name: String = "FSM"
@export_multiline var description: String = ""
@export var start_state: String = ""
@export var states: Array[RCState] = []
## Transitions that can be taken from any state.
@export var global_transitions: Array[RCTransition] = []
## Events declared by this FSM (FINISHED is implicit).
@export var events: PackedStringArray = PackedStringArray()
@export var variables: Array[RCVariable] = []
## Editor-only groups and comment notes drawn in the graph (not used at runtime).
@export var groups: Array[RCGroup] = []

var _var_map: Dictionary = {}
var _state_map: Dictionary = {}


func get_state(n: String) -> RCState:
	if not _state_map.is_empty():
		return _state_map.get(n)
	for s in states:
		if s.state_name == n:
			return s
	return null


func get_variable(n: String) -> RCVariable:
	if not _var_map.is_empty():
		return _var_map.get(n)
	for v in variables:
		if v.name == n:
			return v
	return null


func has_event(e: String) -> bool:
	return e == FINISHED or events.has(e)


func unique_state_name(base: String = "State") -> String:
	if base != "State" and get_state(base) == null:
		return base
	var i := 1 if base == "State" else 2
	var n := "%s %d" % [base, i]
	while get_state(n) != null:
		i += 1
		n = "%s %d" % [base, i]
	return n


func unique_variable_name(base: String = "variable") -> String:
	var n := base
	var i := 1
	while get_variable(n) != null:
		i += 1
		n = "%s%d" % [base, i]
	return n


## Builds an independent copy used by a running [RCFsmComponent].
func create_runtime_copy() -> RCFsm:
	var c := RCFsm.new()
	c.resource_name = resource_name
	c.fsm_name = fsm_name
	c.description = description
	c.start_state = start_state
	c.events = events.duplicate()
	c.states = _clone_states()
	c.global_transitions = _clone_transitions(global_transitions)
	c.variables = _clone_variables()
	for s in c.states:
		c._state_map[s.state_name] = s
	for v in c.variables:
		c._var_map[v.name] = v
	return c


func snapshot() -> Dictionary:
	return {
		"fsm_name": fsm_name,
		"description": description,
		"start_state": start_state,
		"events": events.duplicate(),
		"states": _clone_states(),
		"global_transitions": _clone_transitions(global_transitions),
		"variables": _clone_variables(),
		"groups": _clone_groups(),
	}


func apply_snapshot(snap: Dictionary) -> void:
	var tmp := RCFsm.new()
	tmp.states = snap.states
	tmp.global_transitions = snap.global_transitions
	tmp.variables = snap.variables
	fsm_name = snap.fsm_name
	description = snap.description
	start_state = snap.start_state
	events = snap.events.duplicate()
	states = tmp._clone_states()
	global_transitions = _clone_transitions(snap.global_transitions)
	variables = tmp._clone_variables()
	if snap.has("groups"):
		tmp.groups = snap.groups
	groups = tmp._clone_groups()
	emit_changed()


func _clone_states() -> Array[RCState]:
	var out: Array[RCState] = []
	for s in states:
		if s != null:
			out.append(clone_state(s))
	return out


func _clone_variables() -> Array[RCVariable]:
	var out: Array[RCVariable] = []
	for v in variables:
		if v != null:
			var nv := clone_resource(v) as RCVariable
			nv.value = v.get_value_copy()
			out.append(nv)
	return out


func _clone_groups() -> Array[RCGroup]:
	var out: Array[RCGroup] = []
	for g in groups:
		if g != null:
			var ng := clone_resource(g) as RCGroup
			ng.states = g.states.duplicate()
			out.append(ng)
	return out


static func _clone_transitions(list: Array[RCTransition]) -> Array[RCTransition]:
	var out: Array[RCTransition] = []
	for t in list:
		if t != null:
			out.append(RCTransition.make(t.event, t.to_state))
	return out


static func clone_state(s: RCState) -> RCState:
	var ns := RCState.new()
	ns.state_name = s.state_name
	ns.description = s.description
	ns.position = s.position
	ns.color = s.color
	ns.sequence = s.sequence
	var acts: Array[RCAction] = []
	for a in s.actions:
		if a != null:
			acts.append(clone_resource(a) as RCAction)
	ns.actions = acts
	ns.transitions = _clone_transitions(s.transitions)
	return ns


## Shallow resource copy whose Array/Dictionary properties are not shared with the source.
static func clone_resource(r: Resource) -> Resource:
	var c: Resource = r.duplicate(false)
	for p in r.get_property_list():
		if p.usage & PROPERTY_USAGE_STORAGE and p.name != "script":
			var v: Variant = r.get(p.name)
			if v is Array or v is Dictionary:
				c.set(p.name, v.duplicate(true))
	return c
