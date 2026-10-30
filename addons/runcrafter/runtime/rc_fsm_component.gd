@tool
@icon("res://addons/runcrafter/icons/fsm.svg")
class_name RCFsmComponent
extends Node
## Runs a [RCFsm] (the equivalent of PlayMaker's PlayMakerFSM component).
##
## Add it as a child of the node it should control (the "owner", by default the parent),
## then select it and open the RunCrafter main screen to edit the state machine.

signal state_entered(state_name: String)
signal state_exited(state_name: String)
## Emitted on every transition.
signal state_changed(from_state: String, to_state: String, event: String)
## Emitted for every event received by this FSM (whether it caused a transition or not).
signal event_received(event: String)
## Emitted by the "Emit FSM Signal" action - lets regular GDScript code react to the FSM.
signal custom_signal(signal_name: String, args: Array)
## Emitted when the FSM is finished by the "Finish FSM" action (used by "Run FSM").
signal fsm_finished

const GROUP := &"runcrafter_fsm"
const FINISHED := "FINISHED"

@export var fsm: RCFsm:
	set(v):
		if fsm == v:
			return
		fsm = v
		notify_property_list_changed()
		update_configuration_warnings()
## Node controlled by this FSM. Actions resolve their NodePaths relative to it.
@export var owner_path: NodePath = NodePath("..")
@export var auto_start: bool = true
## Print every transition to the output.
@export var log_transitions: bool = false
## Protection against infinite loops (transitions processed in a single frame).
@export var max_transitions_per_frame: int = 100
## Per-instance overrides of exposed variables (edited through the "Variables" inspector group).
@export_storage var variable_overrides: Dictionary = {}

## Runtime copy of [member fsm] (null until started).
var runtime: RCFsm
var current_state: RCState
var previous_state_name: String = ""
var last_event: String = ""
## Data attached to the last received event (see send_event()).
var last_event_data: Variant = null
## Node that sent the last received event (usually the owner of the sending FSM).
var last_event_sender: Node = null
## Event that caused the transition into the current state, with its data and sender
## (read by the "Get Event Info" action).
var state_event: String = ""
var state_event_data: Variant = null
var state_event_sender: Node = null
## Time (seconds) spent in the current state.
var state_time: float = 0.0
var is_running: bool = false

## Queue items: [event, data, sender, state_serial]. state_serial >= 0 marks a FINISHED
## event that belongs to one particular entry of a state (stale ones are dropped).
var _event_queue: Array = []
var _state_serial: int = 0
var _processing: bool = false
var _entered: Array[RCAction] = []
var _seq_index: int = 0
var _finished_sent: bool = false
var _owner_cache: Node


#region Lifecycle
func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return
	add_to_group(GROUP)
	if auto_start:
		start.call_deferred()


func _exit_tree() -> void:
	if not Engine.is_editor_hint() and is_running:
		stop()


func _get_configuration_warnings() -> PackedStringArray:
	if fsm == null:
		return PackedStringArray(["No FSM assigned. Select this node and open the RunCrafter tab to create one."])
	return PackedStringArray()


func _process(delta: float) -> void:
	if not is_running or current_state == null:
		return
	state_time += delta
	_run_updates(delta, false)


func _physics_process(delta: float) -> void:
	if not is_running or current_state == null:
		return
	_run_updates(delta, true)


func _unhandled_input(event: InputEvent) -> void:
	if not is_running or current_state == null:
		return
	_processing = true
	for a in _entered.duplicate():
		if not a.finished:
			a._on_input(event)
			if _transition_pending():
				break
	_processing = false
	_process_queue()
#endregion


#region Public API
func start() -> void:
	if fsm == null:
		push_warning("RunCrafter: %s has no FSM assigned." % get_path())
		return
	if is_running:
		stop()
	runtime = fsm.create_runtime_copy()
	for k in variable_overrides:
		var v := runtime.get_variable(k)
		if v:
			var val: Variant = variable_overrides[k]
			v.value = val.duplicate(true) if (val is Array or val is Dictionary) else val
	for st in runtime.states:
		for a in st.actions:
			a.fsm = self
	_owner_cache = get_node_or_null(owner_path)
	is_running = true
	current_state = null
	_event_queue.clear()
	var first := runtime.get_state(runtime.start_state)
	if first == null and not runtime.states.is_empty():
		first = runtime.states[0]
	if first == null:
		return
	_processing = true
	_enter_state(first, "START")
	_check_finished()
	_processing = false
	_process_queue()


func stop() -> void:
	if not is_running:
		return
	_processing = true
	_exit_state()
	_processing = false
	is_running = false
	current_state = null
	_event_queue.clear()


## Sends an event to this FSM. If the active state (or a global transition)
## handles it, the FSM changes state. Optional [param data] and [param sender] can be read
## by the receiving state with the "Get Event Info" action.
func send_event(event: String, data: Variant = null, sender: Node = null) -> void:
	if not is_running or event.is_empty():
		return
	_event_queue.append([event, data, sender, -1])
	_process_queue()


func send_event_delayed(event: String, delay: float, data: Variant = null, sender: Node = null) -> void:
	if delay <= 0.0:
		send_event(event, data, sender)
		return
	get_tree().create_timer(delay, false).timeout.connect(func():
		if is_instance_valid(self):
			send_event(event, data, sender))


## Stops the FSM and emits [signal fsm_finished] (used by sub-FSMs started with "Run FSM").
func finish_fsm() -> void:
	if not is_running:
		return
	stop.call_deferred()
	fsm_finished.emit()


## Forces a state change, ignoring transitions.
func goto_state(state_name: String) -> void:
	if not is_running:
		return
	var st := runtime.get_state(state_name)
	if st == null:
		push_error("RunCrafter: state '%s' not found." % state_name)
		return
	_processing = true
	_change_state(st, "")
	_check_finished()
	_processing = false
	_process_queue()


## True when an already received event is going to change the state.
func is_transition_pending() -> bool:
	return _transition_pending()


func get_active_state_name() -> String:
	return current_state.state_name if current_state else ""


func get_fsm_name() -> String:
	return fsm.fsm_name if fsm else ""


func get_owner_node() -> Node:
	if is_instance_valid(_owner_cache):
		return _owner_cache
	_owner_cache = get_node_or_null(owner_path)
	return _owner_cache


## Reads a variable. Local variables shadow globals; prefix with "g:" to force a global.
func get_var(var_name: String) -> Variant:
	var v := _find_var(var_name)
	return v.value if v else null


func set_var(var_name: String, value: Variant) -> void:
	var v := _find_var(var_name)
	if v == null:
		push_warning("RunCrafter: variable '%s' not found in %s." % [var_name, get_path()])
		return
	if v.type == TYPE_OBJECT or value == null or typeof(value) == v.type:
		v.value = value
	else:
		v.value = type_convert(value, v.type)


func has_var(var_name: String) -> bool:
	return _find_var(var_name) != null


func get_all_variable_names() -> PackedStringArray:
	var out := PackedStringArray()
	for v in RCGlobals.get_runtime().variables:
		out.append(v.name)
	var src := runtime if runtime else fsm
	if src:
		for v in src.variables:
			if not out.has(v.name):
				out.append(v.name)
	return out


## Sends an event to every running FSM in the scene tree.
static func broadcast(tree: SceneTree, event: String, delay: float = 0.0, data: Variant = null, sender: Node = null) -> void:
	if tree == null:
		return
	for n in tree.get_nodes_in_group(GROUP):
		if n is RCFsmComponent:
			n.send_event_delayed(event, delay, data, sender)


## Finds a RCFsmComponent on [param node] (the node itself or one of its direct children).
## If [param fsm_name] is not empty, the FSM name must match.
static func find_fsm(node: Node, fsm_name: String = "") -> RCFsmComponent:
	if node == null:
		return null
	if node is RCFsmComponent and (fsm_name.is_empty() or node.get_fsm_name() == fsm_name):
		return node
	for c in node.get_children():
		if c is RCFsmComponent and (fsm_name.is_empty() or c.get_fsm_name() == fsm_name):
			return c
	return null
#endregion


#region State machine core
func _find_var(var_name: String) -> RCVariable:
	if var_name.begins_with("g:"):
		return RCGlobals.get_runtime().get_variable(var_name.substr(2))
	if runtime:
		var v := runtime.get_variable(var_name)
		if v:
			return v
	return RCGlobals.get_runtime().get_variable(var_name)


func _find_transition(event: String) -> RCState:
	if runtime == null:
		return null
	if current_state:
		for t in current_state.transitions:
			if t.event == event and not t.to_state.is_empty():
				return runtime.get_state(t.to_state)
	for t in runtime.global_transitions:
		if t.event == event and not t.to_state.is_empty():
			return runtime.get_state(t.to_state)
	return null


func _transition_pending() -> bool:
	for item in _event_queue:
		if _is_stale(item):
			continue
		if _find_transition(item[0]) != null:
			return true
	return false


func _is_stale(item: Array) -> bool:
	return item[3] >= 0 and item[3] != _state_serial


func _process_queue() -> void:
	if _processing:
		return
	_processing = true
	var count := 0
	while is_running and not _event_queue.is_empty():
		var item: Array = _event_queue.pop_front()
		if _is_stale(item):
			continue
		var ev: String = item[0]
		last_event = ev
		last_event_data = item[1]
		last_event_sender = item[2]
		event_received.emit(ev)
		var target := _find_transition(ev)
		if target == null:
			continue
		count += 1
		if count > max_transitions_per_frame:
			push_error("RunCrafter: %s exceeded %d transitions in one frame (infinite loop?). Last event: %s" % [get_path(), max_transitions_per_frame, ev])
			_event_queue.clear()
			break
		state_event = ev
		state_event_data = item[1]
		state_event_sender = item[2]
		_change_state(target, ev)
		_check_finished()
	_processing = false


func _change_state(target: RCState, event: String) -> void:
	_exit_state()
	_enter_state(target, event)


func _enter_state(st: RCState, event: String) -> void:
	var prev := current_state.state_name if current_state else ""
	if current_state:
		previous_state_name = prev
	current_state = st
	_state_serial += 1
	state_time = 0.0
	_finished_sent = false
	_seq_index = 0
	_entered.clear()
	if log_transitions:
		print("[RunCrafter] %s: %s --%s--> %s" % [get_path(), prev, event, st.state_name])
	_send_debug(st.state_name, event, prev)
	for a in st.actions:
		a.finished = not a.enabled
	state_entered.emit(st.state_name)
	state_changed.emit(prev, st.state_name, event)
	if st.sequence:
		_advance_sequence()
		return
	for a in st.actions:
		if not a.enabled:
			continue
		_enter_action(a)
		if _transition_pending() or current_state != st:
			return


func _enter_action(a: RCAction) -> void:
	_entered.append(a)
	a.finished = false
	a._gm_resolve_bindings()
	a._on_enter()


func _exit_state() -> void:
	if current_state == null:
		return
	for a in _entered:
		a._on_exit()
		a._gm_cleanup()
	_entered.clear()
	state_exited.emit(current_state.state_name)


func _advance_sequence() -> void:
	var st := current_state
	while _seq_index < st.actions.size():
		var a := st.actions[_seq_index]
		if not a.enabled:
			_seq_index += 1
			continue
		if not _entered.has(a):
			_enter_action(a)
			if _transition_pending() or current_state != st:
				return
		if a.finished:
			_seq_index += 1
			continue
		return


func _run_updates(delta: float, physics: bool) -> void:
	_processing = true
	var st := current_state
	if st.sequence:
		if _seq_index < st.actions.size():
			var a := st.actions[_seq_index]
			if a.enabled and not a.finished and _entered.has(a):
				a._gm_resolve_bindings()
				if physics:
					a._on_physics_update(delta)
				else:
					a._on_update(delta)
		if not _transition_pending() and current_state == st:
			_advance_sequence()
	else:
		for a in _entered:
			if not a.finished:
				a._gm_resolve_bindings()
				if physics:
					a._on_physics_update(delta)
				else:
					a._on_update(delta)
				if _transition_pending():
					break
	if current_state == st:
		_check_finished()
	_processing = false
	_process_queue()


func _check_finished() -> void:
	if _finished_sent or current_state == null:
		return
	for a in current_state.actions:
		if a.enabled and not a.finished:
			return
	if current_state.sequence and _seq_index < current_state.actions.size():
		return
	# An action already asked for a transition: FINISHED would be stale.
	if _transition_pending():
		return
	_finished_sent = true
	_event_queue.append([FINISHED, null, null, _state_serial])


func _send_debug(state_name: String, event: String, prev: String) -> void:
	if not EngineDebugger.is_active():
		return
	var scene_file := ""
	var rel_path := ""
	if owner:
		scene_file = owner.scene_file_path
		rel_path = str(owner.get_path_to(self))
	elif get_tree() and get_tree().current_scene:
		scene_file = get_tree().current_scene.scene_file_path
		rel_path = str(get_tree().current_scene.get_path_to(self))
	EngineDebugger.send_message("runcrafter:state", [fsm.resource_path if fsm else "", scene_file,
			rel_path, str(get_path()), state_name, event, prev])
#endregion


#region Inspector: exposed variables
func _get_property_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if fsm == null:
		return out
	var exposed: Array[RCVariable] = []
	for v in fsm.variables:
		if v and v.exposed and not v.name.is_empty():
			exposed.append(v)
	if exposed.is_empty():
		return out
	out.append({"name": "Variables", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": "fsm_var/"})
	for v in exposed:
		var p := {"name": "fsm_var/" + v.name, "type": v.type, "usage": PROPERTY_USAGE_EDITOR}
		if v.type == TYPE_OBJECT:
			p["hint"] = PROPERTY_HINT_RESOURCE_TYPE
			p["hint_string"] = "Resource"
		out.append(p)
	return out


func _get(property: StringName) -> Variant:
	var s := str(property)
	if s.begins_with("fsm_var/") and fsm:
		var n := s.substr(8)
		if variable_overrides.has(n):
			return variable_overrides[n]
		var v := fsm.get_variable(n)
		return v.value if v else null
	return null


func _set(property: StringName, value: Variant) -> bool:
	var s := str(property)
	if s.begins_with("fsm_var/"):
		var n := s.substr(8)
		var v := fsm.get_variable(n) if fsm else null
		if v and typeof(value) == typeof(v.value) and value == v.value:
			variable_overrides.erase(n)
		else:
			variable_overrides[n] = value
		return true
	return false


func _property_can_revert(property: StringName) -> bool:
	var s := str(property)
	return s.begins_with("fsm_var/") and variable_overrides.has(s.substr(8))


func _property_get_revert(property: StringName) -> Variant:
	var s := str(property)
	if s.begins_with("fsm_var/") and fsm:
		var v := fsm.get_variable(s.substr(8))
		return v.value if v else null
	return null
#endregion
