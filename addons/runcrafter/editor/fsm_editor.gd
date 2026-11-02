@tool
extends VBoxContainer
## RunCrafter main screen: graph view of the FSM + State / Events / Variables / Globals / FSM / Log panels.

const PropertyRow := preload("res://addons/runcrafter/editor/property_row.gd")
const ActionBrowser := preload("res://addons/runcrafter/editor/action_browser.gd")
const VariablesPanel := preload("res://addons/runcrafter/editor/variables_panel.gd")

const STATE_COLORS: Array[Color] = [
	Color(0.25, 0.27, 0.32), Color(0.20, 0.35, 0.55), Color(0.18, 0.45, 0.30), Color(0.50, 0.42, 0.15),
	Color(0.55, 0.25, 0.20), Color(0.42, 0.25, 0.52), Color(0.15, 0.45, 0.48), Color(0.45, 0.45, 0.45),
]
const START_COLOR := Color(0.16, 0.55, 0.28)
const DEBUG_COLOR := Color(0.95, 0.55, 0.10)
const FINISHED := "FINISHED"

enum { MENU_ADD_STATE, MENU_PASTE, MENU_SET_START, MENU_DUPLICATE, MENU_DELETE, MENU_COPY,
		MENU_ADD_COMMENT, MENU_GROUP, MENU_UNGROUP_STATE, MENU_EDIT_GROUP, MENU_DELETE_GROUP }

var plugin: EditorPlugin

var _node: RCFsmComponent
## Selected scene node that has no FSM yet (shown with an "Add FSM" button).
var _bare_node: Node
var _fsm: RCFsm
var _globals: RCGlobals
var _selected_state: String = ""
var _debug_state: String = ""
## [from_state, event, to_state] of the last transition seen while debugging.
var _debug_edge: Array = []
## Live variable values from the running game: FSM node path -> [res_path, scene_file, rel_path, locals].
var _live_fsms: Dictionary = {}
## Live values of the global variables (shared by every FSM of the running game).
var _live_globals: Dictionary = {}
## Problems found in the edited FSM (see _collect_issues): {"states": {name: [[level, text]]}, "fsm": [[level, text]]}.
var _issues: Dictionary = {}
var _issues_btn: Button
## Problem list at the top of the State panel (refilled without rebuilding the panel).
var _issues_box: VBoxContainer
var _clipboard: Array[RCState] = []
var _refresh_queued: bool = false
var _graph_nodes: Dictionary = {}
var _node_to_state: Dictionary = {}
var _menu_state: String = ""
var _menu_pos: Vector2 = Vector2.ZERO
## Transition being dragged: {"state": String, "index": int} (empty = not dragging).
var _link_drag: Dictionary = {}
## State under the mouse while dragging a transition.
var _link_hover: String = ""
## Mouse position (graph-local) during a transition drag.
var _link_mouse: Vector2 = Vector2.ZERO
var _transition_menu: PopupMenu
var _transition_event_sub: PopupMenu
var _menu_transition: Dictionary = {}

# UI
var _title_label: Label
var _fsm_picker: OptionButton
var _save_btn: Button
var _template_btn: MenuButton
var _add_state_btn: Button
var _debug_label: Label
var _placeholder: CenterContainer
var _placeholder_label: Label
var _create_btn: Button
var _split: HSplitContainer
var _graph: GraphEdit
var _tabs: TabContainer
var _state_box: VBoxContainer
var _events_box: VBoxContainer
var _vars_panel: VariablesPanel
var _globals_panel: VariablesPanel
var _global_events_box: VBoxContainer
var _fsm_box: VBoxContainer
var _log: RichTextLabel
var _browser: ActionBrowser
var _graph_menu: PopupMenu
## Right-click menu of a group / comment frame.
var _group_menu: PopupMenu
## Index (in _fsm.groups) of the group the group menu was opened for.
var _menu_group: int = -1
## GraphFrame name -> index in _fsm.groups.
var _frame_to_group: Dictionary = {}
var _node_menu: PopupMenu
var _transition_sub: PopupMenu
var _global_sub: PopupMenu
var _file_dialog: EditorFileDialog
var _globals_save_timer: Timer


#region UI construction
func _ready() -> void:
	# User content (state, event and variable names) must never be run through editor translations.
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	theme = _make_compact_theme()
	_globals = RCGlobals.load_for_editor()
	_build_toolbar()

	_placeholder = CenterContainer.new()
	_placeholder.size_flags_vertical = SIZE_EXPAND_FILL
	var pv := VBoxContainer.new()
	_placeholder.add_child(pv)
	_placeholder_label = Label.new()
	_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(_placeholder_label)
	_create_btn = Button.new()
	_create_btn.text = "Create FSM"
	_create_btn.pressed.connect(_create_fsm_for_node)
	pv.add_child(_create_btn)
	add_child(_placeholder)

	_split = HSplitContainer.new()
	_split.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(_split)

	_graph = GraphEdit.new()
	_graph.size_flags_horizontal = SIZE_EXPAND_FILL
	# Transitions are drawn by _draw_links() (PlayMaker-style routing), not by GraphEdit itself.
	_graph.draw.connect(_draw_links)
	_graph.scroll_offset_changed.connect(func(_o: Vector2) -> void: _graph.queue_redraw())
	_graph.node_deselected.connect(func(_n: Node) -> void: _graph.queue_redraw())
	_graph.show_arrange_button = false
	_graph.minimap_enabled = true
	_graph.delete_nodes_request.connect(_on_delete_nodes_request)
	_graph.node_selected.connect(_on_node_selected)
	_graph.end_node_move.connect(_on_end_node_move)
	_graph.popup_request.connect(_on_graph_popup_request)
	_graph.duplicate_nodes_request.connect(_on_duplicate_nodes_request)
	_graph.copy_nodes_request.connect(_on_copy_nodes_request)
	_graph.paste_nodes_request.connect(_on_paste_nodes_request)
	_graph.graph_elements_linked_to_frame_request.connect(_on_linked_to_frame)
	_split.add_child(_graph)

	_tabs = TabContainer.new()
	_tabs.custom_minimum_size.x = 430 * EditorInterface.get_editor_scale()
	_split.add_child(_tabs)
	_state_box = _add_scroll_tab("State")
	_events_box = _add_scroll_tab("Events")
	var vars_scroll := _add_scroll_tab("Variables")
	_vars_panel = VariablesPanel.new()
	_vars_panel.ctx = self
	_vars_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	vars_scroll.add_child(_vars_panel)
	var globals_box := _add_scroll_tab("Globals")
	_globals_panel = VariablesPanel.new()
	_globals_panel.ctx = self
	_globals_panel.is_global = true
	_globals_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	globals_box.add_child(_globals_panel)
	_global_events_box = VBoxContainer.new()
	globals_box.add_child(_global_events_box)
	_fsm_box = _add_scroll_tab("FSM")
	var log_box := VBoxContainer.new()
	log_box.name = "Log"
	_tabs.add_child(log_box)
	var log_bar := HBoxContainer.new()
	log_box.add_child(log_bar)
	var log_info := Label.new()
	log_info.text = "Transitions of running games (Debug)"
	log_info.size_flags_horizontal = SIZE_EXPAND_FILL
	log_bar.add_child(log_info)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(func() -> void: _log.clear())
	log_bar.add_child(clear_btn)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.size_flags_vertical = SIZE_EXPAND_FILL
	log_box.add_child(_log)

	_browser = ActionBrowser.new()
	add_child(_browser)
	_browser.action_chosen.connect(_on_action_chosen)

	_graph_menu = PopupMenu.new()
	add_child(_graph_menu)
	_graph_menu.id_pressed.connect(_on_graph_menu)
	_group_menu = PopupMenu.new()
	add_child(_group_menu)
	_group_menu.id_pressed.connect(_on_group_menu)
	_node_menu = PopupMenu.new()
	add_child(_node_menu)
	_node_menu.id_pressed.connect(_on_node_menu)
	_transition_sub = PopupMenu.new()
	_transition_sub.id_pressed.connect(func(id: int) -> void:
		_add_transition(_menu_state, _transition_sub.get_item_text(_transition_sub.get_item_index(id)))
	)
	_global_sub = PopupMenu.new()
	_global_sub.id_pressed.connect(func(id: int) -> void:
		_add_global_transition(_global_sub.get_item_text(_global_sub.get_item_index(id)), _menu_state)
	)
	_transition_sub.name = "TransitionSub"
	_global_sub.name = "GlobalSub"
	_node_menu.add_child(_transition_sub)
	_node_menu.add_child(_global_sub)

	_transition_menu = PopupMenu.new()
	add_child(_transition_menu)
	_transition_menu.id_pressed.connect(_on_transition_menu)
	_transition_event_sub = PopupMenu.new()
	_transition_event_sub.name = "TransitionEventSub"
	_transition_event_sub.id_pressed.connect(_on_transition_event_chosen)
	_transition_menu.add_child(_transition_event_sub)

	_file_dialog = EditorFileDialog.new()
	_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_file_dialog.add_filter("*.tres", "FSM Template")
	add_child(_file_dialog)

	_globals_save_timer = Timer.new()
	_globals_save_timer.one_shot = true
	_globals_save_timer.wait_time = 0.6
	_globals_save_timer.timeout.connect(_save_globals)
	add_child(_globals_save_timer)

	_do_refresh()


func _build_toolbar() -> void:
	var bar := HBoxContainer.new()
	add_child(bar)
	var et := EditorInterface.get_editor_theme()
	_title_label = Label.new()
	_title_label.text = "RunCrafter"
	bar.add_child(_title_label)
	_fsm_picker = OptionButton.new()
	_fsm_picker.tooltip_text = "This node has several FSMs - pick one"
	_fsm_picker.item_selected.connect(func(i: int) -> void:
		var target: Variant = _fsm_picker.get_item_metadata(i)
		if target is RCFsmComponent and is_instance_valid(target) and target != _node:
			edit_object(target)
	)
	bar.add_child(_fsm_picker)
	bar.add_child(VSeparator.new())
	_add_state_btn = Button.new()
	_add_state_btn.text = "Add State"
	_add_state_btn.icon = et.get_icon("Add", "EditorIcons")
	_add_state_btn.flat = true
	_add_state_btn.pressed.connect(func() -> void:
		var center := (_graph.scroll_offset + _graph.size * 0.5) / _graph.zoom
		_add_state(center - Vector2(80, 30))
	)
	bar.add_child(_add_state_btn)
	_template_btn = MenuButton.new()
	_template_btn.text = "Template"
	_template_btn.flat = true
	_template_btn.icon = et.get_icon("Load", "EditorIcons")
	var tp := _template_btn.get_popup()
	tp.add_item("Save Copy as Template…", 0)
	tp.add_item("Use Template… (shared .tres)", 1)
	tp.add_item("Make Unique (embed a copy)", 2)
	tp.id_pressed.connect(_on_template_menu)
	bar.add_child(_template_btn)
	_save_btn = Button.new()
	_save_btn.text = "Save Template"
	_save_btn.icon = et.get_icon("Save", "EditorIcons")
	_save_btn.flat = true
	_save_btn.tooltip_text = "This FSM is a shared .tres file - save it."
	_save_btn.pressed.connect(save_external)
	bar.add_child(_save_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_issues_btn = Button.new()
	_issues_btn.flat = true
	_issues_btn.visible = false
	_issues_btn.pressed.connect(_select_next_issue)
	bar.add_child(_issues_btn)
	_debug_label = Label.new()
	_debug_label.add_theme_color_override("font_color", DEBUG_COLOR)
	bar.add_child(_debug_label)
	var help := Button.new()
	help.flat = true
	help.icon = et.get_icon("Help", "EditorIcons")
	help.tooltip_text = "Quick help"
	help.pressed.connect(_show_help)
	bar.add_child(help)


func _add_scroll_tab(tab_name: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = tab_name
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(sc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = SIZE_EXPAND_FILL
	sc.add_child(vb)
	return vb
#endregion


#region Editing target
func edit_object(o: Object) -> void:
	if o is RCFsmComponent:
		_set_node(o)
		_fsm = o.fsm
	elif o is RCFsm:
		if not (_node and is_instance_valid(_node) and _node.fsm == o):
			_set_node(null)
		_fsm = o
	else:
		return
	_bare_node = null
	_selected_state = ""
	_debug_state = ""
	if _fsm and not _fsm.states.is_empty():
		_selected_state = _fsm.start_state if _fsm.get_state(_fsm.start_state) else _fsm.states[0].state_name
	queue_refresh()


func clear_edit() -> void:
	_set_node(null)
	_bare_node = null
	_fsm = null
	_selected_state = ""
	queue_refresh()


## Shows the empty screen for a selected node without an FSM, with an "Add FSM" button.
func show_no_fsm(n: Node) -> void:
	clear_edit()
	_bare_node = n


func get_edited_node() -> RCFsmComponent:
	return _node if _node and is_instance_valid(_node) else null


func _set_node(n: RCFsmComponent) -> void:
	if _node and is_instance_valid(_node) and _node.property_list_changed.is_connected(_on_node_property_list_changed):
		_node.property_list_changed.disconnect(_on_node_property_list_changed)
	_node = n
	if _node:
		_node.property_list_changed.connect(_on_node_property_list_changed)


func _on_node_property_list_changed() -> void:
	if _node and is_instance_valid(_node) and _node.fsm != _fsm:
		_fsm = _node.fsm
		_selected_state = _fsm.states[0].state_name if _fsm and not _fsm.states.is_empty() else ""
		queue_refresh()


## "Create FSM" / "Add FSM" button: fills an empty RCFsmComponent, or adds a new one to a
## selected node that has no FSM.
func _create_fsm_for_node() -> void:
	if _bare_node and is_instance_valid(_bare_node):
		_add_fsm_component()
		return
	if _node == null or not is_instance_valid(_node):
		return
	var f := _new_fsm()
	var ur := plugin.get_undo_redo()
	ur.create_action("RunCrafter: Create FSM", UndoRedo.MERGE_DISABLE, _node)
	ur.add_do_property(_node, "fsm", f)
	ur.add_undo_property(_node, "fsm", _node.fsm)
	ur.commit_action()
	_fsm = f
	_selected_state = f.start_state
	queue_refresh()


## Adds an RCFsmComponent with a new FSM as a child of the selected node (like adding a
## PlayMakerFSM component to a GameObject) and opens it.
func _add_fsm_component() -> void:
	var target := _bare_node
	var root := EditorInterface.get_edited_scene_root()
	if target == null or not is_instance_valid(target) or root == null:
		return
	var comp := RCFsmComponent.new()
	comp.name = "FSM"
	comp.fsm = _new_fsm()
	var ur := plugin.get_undo_redo()
	ur.create_action("RunCrafter: Add FSM", UndoRedo.MERGE_DISABLE, target)
	ur.add_do_method(target, "add_child", comp, true)
	ur.add_do_property(comp, "owner", root)
	ur.add_do_method(self, "edit_object", comp)
	ur.add_do_reference(comp)
	ur.add_undo_method(target, "remove_child", comp)
	ur.add_undo_method(self, "show_no_fsm", target)
	ur.commit_action()


func _new_fsm() -> RCFsm:
	var f := RCFsm.new()
	f.fsm_name = "FSM"
	var st := RCState.new()
	st.state_name = "State 1"
	st.position = Vector2(80, 80)
	f.states.append(st)
	f.start_state = st.state_name
	return f
#endregion


#region Undo / redo
## Runs [param mutator] (which changes the edited FSM) and records an undoable action.
func modify(action_name: String, mutator: Callable, merge: bool = false, rebuild: bool = true) -> void:
	if _fsm == null:
		return
	var before := _fsm.snapshot()
	mutator.call()
	var after := _fsm.snapshot()
	var ur := plugin.get_undo_redo()
	var context: Object = _node if _node and is_instance_valid(_node) else _fsm
	ur.create_action("RunCrafter: " + action_name, UndoRedo.MERGE_ENDS if merge else UndoRedo.MERGE_DISABLE, context)
	ur.add_do_method(self, &"_restore", _fsm, after)
	ur.add_undo_method(self, &"_restore", _fsm, before)
	ur.commit_action(false)
	_fsm.emit_changed()
	if _node and is_instance_valid(_node):
		_node.notify_property_list_changed()
	if rebuild:
		queue_refresh()
	else:
		_refresh_issues()


func _restore(fsm: RCFsm, snap: Dictionary) -> void:
	fsm.apply_snapshot(snap)
	if fsm == _fsm:
		if _node and is_instance_valid(_node):
			_node.notify_property_list_changed()
		queue_refresh()


## Used by the variables panels: FSM variables are undoable, global variables are saved to disk.
func modify_variables(source: Resource, action_name: String, mutator: Callable, merge: bool = false, rebuild: bool = true) -> void:
	if source is RCGlobals:
		mutator.call()
		_globals_save_timer.start()
		if rebuild:
			queue_refresh()
	else:
		modify(action_name, mutator, merge, rebuild)


func _save_globals() -> void:
	if _globals == null:
		return
	var path := RCGlobals.globals_path()
	var err := ResourceSaver.save(_globals, path)
	if err != OK:
		push_error("RunCrafter: could not save globals to %s (error %d)." % [path, err])
		return
	_globals.take_over_path(path)
	EditorInterface.get_resource_filesystem().update_file(path)


## Saves the FSM when it is a standalone .tres file (template).
func save_external() -> void:
	if _globals_save_timer and not _globals_save_timer.is_stopped():
		_globals_save_timer.stop()
		_save_globals()
	if _fsm and _is_file_resource(_fsm):
		var err := ResourceSaver.save(_fsm, _fsm.resource_path)
		if err != OK:
			push_error("RunCrafter: could not save %s (error %d)." % [_fsm.resource_path, err])


func _is_file_resource(r: Resource) -> bool:
	return not r.resource_path.is_empty() and not r.resource_path.contains("::")
#endregion


#region Refresh
func queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_do_refresh.call_deferred()


func _do_refresh() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	if _node and not is_instance_valid(_node):
		_node = null
		_fsm = null
	if _node and _node.fsm != _fsm:
		_fsm = _node.fsm
	if _fsm and not _selected_state.is_empty() and _fsm.get_state(_selected_state) == null:
		_selected_state = ""
	var has_fsm := _fsm != null
	_placeholder.visible = not has_fsm
	_split.visible = has_fsm
	_add_state_btn.disabled = not has_fsm
	_template_btn.disabled = not has_fsm
	_save_btn.visible = has_fsm and _is_file_resource(_fsm)
	if not has_fsm:
		if _bare_node and not is_instance_valid(_bare_node):
			_bare_node = null
		_create_btn.visible = _node != null or _bare_node != null
		_create_btn.text = "Add FSM" if _bare_node else "Create FSM"
		if _node:
			_placeholder_label.text = "'%s' has no FSM yet." % _node.name
		elif _bare_node:
			_placeholder_label.text = "'%s' has no FSM.\nAdd one to give this node a state machine." % _bare_node.name
		else:
			_placeholder_label.text = "Select a node with a RCFsmComponent (or a RCFsm .tres file) to edit it.\nAdd a RCFsmComponent as a child of any node to give it a state machine."
		_title_label.text = "RunCrafter"
		_fsm_picker.visible = false
		_issues_btn.visible = false
		_clear_graph()
		return
	var title := "FSM: %s" % _fsm.fsm_name
	if _node:
		title += "   on   %s" % (_node.get_parent().name if _node.get_parent() else _node.name)
	if _is_file_resource(_fsm):
		title += "   [template: %s]" % _fsm.resource_path.get_file()
	_title_label.text = title
	_update_fsm_picker()
	_rebuild_graph()
	_rebuild_state_panel()
	_rebuild_events_panel()
	_vars_panel.source = _fsm
	_vars_panel.rebuild()
	_globals_panel.source = _globals
	_globals_panel.rebuild()
	_update_live_values()
	_rebuild_global_events()
	_rebuild_fsm_panel()


## Shows a drop-down when the owner of the edited FSM has several RCFsmComponent children.
func _update_fsm_picker() -> void:
	_fsm_picker.clear()
	_fsm_picker.visible = false
	if _node == null or not is_instance_valid(_node) or _node.get_parent() == null:
		return
	var siblings: Array[RCFsmComponent] = []
	for c in _node.get_parent().get_children():
		if c is RCFsmComponent:
			siblings.append(c)
	if siblings.size() < 2:
		return
	for c in siblings:
		_fsm_picker.add_item("%s (%s)" % [c.get_fsm_name() if c.fsm else "-", c.name])
		_fsm_picker.set_item_metadata(_fsm_picker.item_count - 1, c)
		if c == _node:
			_fsm_picker.select(_fsm_picker.item_count - 1)
	_fsm_picker.visible = true


func _clear_children(c: Node) -> void:
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()
#endregion


#region Graph
func _clear_graph() -> void:
	for c in _graph.get_children():
		if c is GraphNode or c is GraphFrame:
			_graph.remove_child(c)
			c.queue_free()
	_graph_nodes.clear()
	_node_to_state.clear()
	_frame_to_group.clear()


func _rebuild_graph() -> void:
	_clear_graph()
	_issues = _collect_issues()
	var s := EditorInterface.get_editor_scale()
	for i in _fsm.states.size():
		var st := _fsm.states[i]
		if st == null:
			continue
		var gn := GraphNode.new()
		gn.name = "S%d" % i
		gn.position_offset = st.position
		# Compact like PlayMaker: title bar + one short row per event, no extra lines.
		gn.custom_minimum_size = Vector2(110, 0) * s
		gn.add_theme_constant_override("separation", 0)
		for j in st.transitions.size():
			var t := st.transitions[j]
			# The whole event row is the drag handle of the transition (like PlayMaker).
			var l := Label.new()
			l.text = t.event if not t.event.is_empty() else "(no event)"
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.add_theme_font_size_override("font_size", _graph_font_size())
			l.mouse_filter = Control.MOUSE_FILTER_STOP
			l.mouse_default_cursor_shape = Control.CURSOR_DRAG
			l.tooltip_text = "Drag onto a state to connect this transition. Right-click for options."
			l.add_theme_color_override("font_color", _event_color(t.event))
			if t.to_state.is_empty():
				l.modulate = Color(1, 1, 1, 0.55)
			l.gui_input.connect(_on_transition_row_input.bind(st.state_name, j))
			gn.add_child(l)
		gn.gui_input.connect(_on_graph_node_gui_input.bind(st.state_name))
		gn.item_rect_changed.connect(_graph.queue_redraw)
		_graph.add_child(gn)
		_graph_nodes[st.state_name] = gn
		_node_to_state[String(gn.name)] = st.state_name
		_style_graph_node(gn, st)
	_build_frames()
	if _graph_nodes.has(_selected_state):
		_graph.set_selected(_graph_nodes[_selected_state])
	_fill_issues_box()
	_graph.queue_redraw()


#region Groups and comments (editor-only frames, like Bolt's groups)
const GROUP_COLORS: Array[Color] = [Color(0.35, 0.5, 0.7), Color(0.35, 0.6, 0.4), Color(0.7, 0.55, 0.3),
		Color(0.65, 0.35, 0.35), Color(0.55, 0.4, 0.7), Color(0.45, 0.45, 0.45)]


func _build_frames() -> void:
	var s := EditorInterface.get_editor_scale()
	for i in _fsm.groups.size():
		var g := _fsm.groups[i]
		if g == null:
			continue
		var fr := GraphFrame.new()
		fr.name = "G%d" % i
		fr.title = g.title if not g.title.is_empty() else ("Comment" if g.is_comment() else "Group")
		fr.position_offset = g.position
		_style_frame(fr, g, s)
		if g.is_comment():
			fr.autoshrink_enabled = false
			fr.resizable = true
			var l := Label.new()
			l.text = g.text
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_vertical = SIZE_EXPAND_FILL
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			# A wrapping label needs a known width, otherwise it asks for a huge height.
			var text_width := func(w: float) -> float: return maxf(40.0 * s, w - 20.0 * s)
			l.custom_minimum_size.x = text_width.call(g.size.x)
			fr.add_child(l)
			fr.size = g.size
			fr.resize_request.connect(func(new_size: Vector2) -> void:
				l.custom_minimum_size.x = text_width.call(new_size.x)
				fr.size = new_size
			)
			fr.resize_end.connect(func(_s: Vector2) -> void: _on_end_node_move())
		else:
			fr.autoshrink_enabled = true
			fr.autoshrink_margin = int(16 * s)
			fr.tooltip_text = g.text
		fr.gui_input.connect(_on_frame_gui_input.bind(i))
		_graph.add_child(fr)
		_frame_to_group[String(fr.name)] = i
		for n in g.states:
			if _graph_nodes.has(n):
				_graph.attach_graph_element_to_frame(_graph_nodes[n].name, fr.name)


## Translucent frame, so transitions drawn behind it stay visible.
func _style_frame(fr: GraphFrame, g: RCGroup, s: float) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(g.color, 0.16)
	panel.border_color = Color(g.color, 0.7)
	panel.set_border_width_all(int(1 * s))
	panel.set_corner_radius_all(int(6 * s))
	panel.set_content_margin_all(8 * s)
	var panel_sel: StyleBoxFlat = panel.duplicate()
	panel_sel.border_color = Color(g.color.lightened(0.4), 0.95)
	panel_sel.set_border_width_all(int(2 * s))
	fr.add_theme_stylebox_override("panel", panel)
	fr.add_theme_stylebox_override("panel_selected", panel_sel)
	var tb := StyleBoxFlat.new()
	tb.bg_color = Color(g.color, 0.75)
	tb.corner_radius_top_left = int(6 * s)
	tb.corner_radius_top_right = int(6 * s)
	tb.content_margin_left = 8 * s
	tb.content_margin_right = 8 * s
	tb.content_margin_top = 2 * s
	tb.content_margin_bottom = 2 * s
	var tbs: StyleBoxFlat = tb.duplicate()
	tbs.bg_color = Color(g.color.lightened(0.2), 0.9)
	fr.add_theme_stylebox_override("titlebar", tb)
	fr.add_theme_stylebox_override("titlebar_selected", tbs)


## Saves the position (and, for comments, the size) of every frame.
func _store_frame_rects() -> void:
	for fname in _frame_to_group:
		var i: int = _frame_to_group[fname]
		var fr := _graph.get_node_or_null(NodePath(fname)) as GraphFrame
		if fr == null or i >= _fsm.groups.size():
			continue
		_fsm.groups[i].position = fr.position_offset
		if _fsm.groups[i].is_comment():
			_fsm.groups[i].size = fr.size


func _on_frame_gui_input(ev: InputEvent, index: int) -> void:
	if not ev is InputEventMouseButton or not ev.pressed:
		return
	if ev.button_index == MOUSE_BUTTON_RIGHT:
		_menu_group = index
		var g := _fsm.groups[index]
		_group_menu.clear()
		_group_menu.add_item("Edit Comment…" if g.is_comment() else "Edit Group…", MENU_EDIT_GROUP)
		_group_menu.add_item("Delete Comment" if g.is_comment() else "Ungroup (keep states)", MENU_DELETE_GROUP)
		_popup_at_mouse(_group_menu)
		get_viewport().set_input_as_handled()
	elif ev.button_index == MOUSE_BUTTON_LEFT and ev.double_click:
		_edit_group(index)
		get_viewport().set_input_as_handled()


func _on_group_menu(id: int) -> void:
	if _menu_group < 0 or _menu_group >= _fsm.groups.size():
		return
	var g := _fsm.groups[_menu_group]
	match id:
		MENU_EDIT_GROUP:
			_edit_group(_menu_group)
		MENU_DELETE_GROUP:
			modify("Delete Comment" if g.is_comment() else "Ungroup", func() -> void: _fsm.groups.erase(g))


func _add_comment(pos: Vector2) -> void:
	var g := RCGroup.new()
	g.title = "Comment"
	g.text = "Double-click to edit."
	g.position = pos
	g.color = GROUP_COLORS[4]
	modify("Add Comment", func() -> void: _fsm.groups.append(g))
	_edit_group.call_deferred(_fsm.groups.size() - 1)


func _group_states(names: Array[String]) -> void:
	if names.is_empty():
		return
	var g := RCGroup.new()
	g.title = "Group"
	g.color = GROUP_COLORS[_fsm.groups.size() % GROUP_COLORS.size()]
	g.states = PackedStringArray(names)
	modify("Group States", func() -> void:
		_remove_from_groups(names)
		_fsm.groups.append(g)
	)
	_edit_group.call_deferred(_fsm.groups.size() - 1)


## Takes states out of their groups; groups left empty are removed.
func _remove_from_groups(names: Array[String]) -> void:
	for g: RCGroup in _fsm.groups.duplicate():
		if g.is_comment():
			continue
		for n in names:
			var i := g.states.find(n)
			if i >= 0:
				g.states.remove_at(i)
		if g.states.is_empty():
			_fsm.groups.erase(g)


func _group_of_state(state_name: String) -> int:
	for i in _fsm.groups.size():
		if _fsm.groups[i] and not _fsm.groups[i].is_comment() and _fsm.groups[i].states.has(state_name):
			return i
	return -1


## States dropped onto a group frame join that group (comments do not take states).
func _on_linked_to_frame(elements: Array, frame: StringName) -> void:
	if not _frame_to_group.has(String(frame)):
		return
	var g := _fsm.groups[_frame_to_group[String(frame)]]
	if g.is_comment():
		return
	var names: Array[String] = []
	for e in elements:
		var n := _state_of(e)
		if not n.is_empty() and not g.states.has(n):
			names.append(n)
	if names.is_empty():
		return
	modify("Add to Group", func() -> void:
		_remove_from_groups(names)
		if not _fsm.groups.has(g):
			_fsm.groups.append(g)
		for n in names:
			g.states.append(n)
	)


## Dialog to edit the title, text and color of a group or comment.
func _edit_group(index: int) -> void:
	if index < 0 or index >= _fsm.groups.size():
		return
	var g := _fsm.groups[index]
	var es := EditorInterface.get_editor_scale()
	var d := ConfirmationDialog.new()
	d.title = "Edit Comment" if g.is_comment() else "Edit Group"
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(340, 0) * es
	d.add_child(vb)
	var title_edit := LineEdit.new()
	title_edit.text = g.title
	title_edit.placeholder_text = "Title"
	vb.add_child(title_edit)
	var text_edit := TextEdit.new()
	text_edit.text = g.text
	text_edit.placeholder_text = "Comment text…" if g.is_comment() else "Notes (shown as a tooltip)…"
	text_edit.custom_minimum_size.y = 100 * es
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vb.add_child(text_edit)
	var colors := HBoxContainer.new()
	vb.add_child(colors)
	var chosen := [g.color]
	var cp := ColorPickerButton.new()
	cp.color = g.color
	cp.custom_minimum_size = Vector2(40, 0) * es
	cp.color_changed.connect(func(c: Color) -> void: chosen[0] = c)
	for c in GROUP_COLORS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(22, 22) * es
		var sb := StyleBoxFlat.new()
		sb.bg_color = c
		sb.set_corner_radius_all(int(3 * es))
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.pressed.connect(func() -> void:
			chosen[0] = c
			cp.color = c
		)
		colors.add_child(b)
	colors.add_child(cp)
	d.confirmed.connect(func() -> void:
		var t := title_edit.text
		var x := text_edit.text
		var c: Color = chosen[0]
		modify("Edit Comment" if g.is_comment() else "Edit Group", func() -> void:
			g.title = t
			g.text = x
			g.color = c
		)
	)
	d.visibility_changed.connect(func() -> void:
		if not d.visible:
			d.queue_free()
	)
	add_child(d)
	d.popup_centered()
	title_edit.grab_focus()
	title_edit.select_all()
#endregion


#region Problem checks (shown in the editor before the game runs)
const ISSUE_WARNING := 1
const ISSUE_ERROR := 2
const ISSUE_COLORS := {1: Color(1.0, 0.8, 0.3), 2: Color(1.0, 0.4, 0.35)}


## Finds problems that would make the FSM misbehave at runtime: missing targets,
## variables or states, syntax errors in expressions, unconnected or unreachable parts.
func _collect_issues() -> Dictionary:
	var by_state := {}
	var general: Array = []
	if _fsm == null:
		return {"states": by_state, "fsm": general}
	if _fsm.states.is_empty():
		general.append([ISSUE_WARNING, "The FSM has no states."])
	elif _fsm.get_state(_fsm.start_state) == null:
		general.append([ISSUE_ERROR, "No start state is set (right-click a state > Set as Start State)."])
	for gt in _fsm.global_transitions:
		if gt and not gt.to_state.is_empty() and _fsm.get_state(gt.to_state) == null:
			general.append([ISSUE_ERROR, "Global transition '%s' leads to a missing state '%s'." % [gt.event, gt.to_state]])
	var var_names := {}
	for v in _fsm.variables:
		if v:
			var_names[v.name] = true
	if _globals:
		for v in _globals.variables:
			if v:
				var_names[v.name] = true
				var_names["g:" + v.name] = true
	var owner_node: Node = null
	if _node and is_instance_valid(_node) and _node.is_inside_tree():
		owner_node = _node.get_node_or_null(_node.owner_path)
	# States reachable by a transition, a global transition or an action that names them.
	var reached := {_fsm.start_state: true}
	for gt in _fsm.global_transitions:
		if gt:
			reached[gt.to_state] = true
	for st in _fsm.states:
		if st == null:
			continue
		for t in st.transitions:
			if t and t.to_state != st.state_name:
				reached[t.to_state] = true
		for a in st.actions:
			if a:
				for p in _action_properties(a):
					var val: Variant = a.get(p.name)
					if val is String:
						reached[val] = true
	for st in _fsm.states:
		if st == null:
			continue
		var list: Array = []
		if not reached.has(st.state_name):
			list.append([ISSUE_WARNING, "No transition leads to this state."])
		for t in st.transitions:
			if t == null:
				continue
			var ev_name := t.event if not t.event.is_empty() else "(no event)"
			if t.event.is_empty():
				list.append([ISSUE_WARNING, "A transition has no event."])
			if t.to_state.is_empty():
				list.append([ISSUE_WARNING, "Event %s is not connected to a state." % ev_name])
			elif _fsm.get_state(t.to_state) == null:
				list.append([ISSUE_ERROR, "Event %s leads to a missing state '%s'." % [ev_name, t.to_state]])
		for a in st.actions:
			if a == null:
				list.append([ISSUE_ERROR, "An action is missing (its script was deleted?)."])
			elif a.enabled:
				_check_action(a, var_names, owner_node, list)
		if not list.is_empty():
			by_state[st.state_name] = list
	return {"states": by_state, "fsm": general}


func _check_action(a: RCAction, var_names: Dictionary, owner_node: Node, list: Array) -> void:
	var title := a.get_title()
	for p in _action_properties(a):
		if p.usage & (PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP):
			continue
		var prop: String = p.name
		var label := prop.capitalize()
		if a.bindings.has(prop):
			var bound := str(a.bindings[prop])
			if not var_names.has(bound):
				list.append([ISSUE_ERROR, "%s: %s uses a missing variable '%s'." % [title, label, bound]])
			continue
		var val: Variant = a.get(prop)
		if val is NodePath:
			if owner_node and not val.is_empty() and owner_node.get_node_or_null(val) == null:
				list.append([ISSUE_WARNING, "%s: %s – node '%s' not found (fine if it is created while the game runs)." % [title, label, val]])
		elif val is String and not val.is_empty():
			if PropertyRow.is_variable_property(prop) and not var_names.has(val):
				list.append([ISSUE_ERROR, "%s: %s – variable '%s' does not exist." % [title, label, val]])
			elif prop.ends_with("expression"):
				var e := Expression.new()
				if e.parse(val, PackedStringArray(var_names.keys())) != OK:
					list.append([ISSUE_ERROR, "%s: %s – %s in '%s'." % [title, label, e.get_error_text(), val]])


## Highest problem level of a state (0 = none).
func _issue_level(state_name: String) -> int:
	var level := 0
	for issue in _issues.get("states", {}).get(state_name, []):
		level = maxi(level, issue[0])
	return level


## Recomputes the problems after an edit that does not rebuild the whole editor.
func _refresh_issues() -> void:
	_issues = _collect_issues()
	_restyle_graph()
	_fill_issues_box()


func _fill_issues_box() -> void:
	var total := 0
	var errors := 0
	var lines := PackedStringArray()
	for issue in _issues.get("fsm", []):
		total += 1
		errors += 1 if issue[0] == ISSUE_ERROR else 0
		lines.append(issue[1])
	var by_state: Dictionary = _issues.get("states", {})
	for n in by_state:
		for issue in by_state[n]:
			total += 1
			errors += 1 if issue[0] == ISSUE_ERROR else 0
			lines.append("%s: %s" % [n, issue[1]])
	if _issues_btn:
		_issues_btn.visible = total > 0
		_issues_btn.text = "%d problem%s" % [total, "" if total == 1 else "s"]
		_issues_btn.icon = EditorInterface.get_editor_theme().get_icon(
				"StatusError" if errors > 0 else "StatusWarning", "EditorIcons")
		_issues_btn.add_theme_color_override("font_color", ISSUE_COLORS[ISSUE_ERROR if errors > 0 else ISSUE_WARNING])
		_issues_btn.tooltip_text = "\n".join(lines) + "\n\nClick to select the next state with a problem."
	if _issues_box == null or not is_instance_valid(_issues_box):
		return
	_clear_children(_issues_box)
	var list: Array = _issues.get("fsm", []) + by_state.get(_selected_state, [])
	for issue in list:
		var l := Label.new()
		l.text = "⚠ " + issue[1]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_color_override("font_color", ISSUE_COLORS[issue[0]])
		_issues_box.add_child(l)


## Toolbar problem counter: selects the next state that has a problem.
func _select_next_issue() -> void:
	var names: Array = _issues.get("states", {}).keys()
	if names.is_empty():
		return
	var i := names.find(_selected_state)
	var next: String = names[(i + 1) % names.size()]
	if _graph_nodes.has(next):
		_graph.set_selected(_graph_nodes[next])
		_graph.scroll_offset = _graph_nodes[next].position_offset * _graph.zoom - _graph.size * 0.4
#endregion


#region Transition drawing
## Draws all transitions (PlayMaker style): a link leaves the event row on the side facing
## the target state and enters the target's title bar from the side, with an arrowhead.
## Targets in the same column get a bracket-shaped link on one side instead of crossing nodes.
func _draw_links() -> void:
	if _fsm == null or _graph_nodes.is_empty():
		return
	var z := _graph.zoom
	var es := EditorInterface.get_editor_scale()
	var focus := _selected_state if _graph_nodes.has(_selected_state) else ""
	var globals := {}
	for gt in _fsm.global_transitions:
		if gt and _graph_nodes.has(gt.to_state):
			if not globals.has(gt.to_state):
				globals[gt.to_state] = PackedStringArray()
			globals[gt.to_state].append(gt.event)
	# Dimmed links first, highlighted ones on top.
	for pass_i in 2:
		for st in _fsm.states:
			if st == null or not _graph_nodes.has(st.state_name):
				continue
			var gn: GraphNode = _graph_nodes[st.state_name]
			for j in st.transitions.size():
				var t := st.transitions[j]
				var dragged: bool = not _link_drag.is_empty() and _link_drag.state == st.state_name and _link_drag.index == j
				if not _graph_nodes.has(t.to_state) or dragged:
					if pass_i == 0 and not dragged:
						# Unconnected transition: hollow handle on the row.
						_graph.draw_arc(Vector2(_node_rect(gn).end.x, _row_y(gn, j)), 4.0 * z * es, 0, TAU, 16,
								_event_color(t.event), 1.5 * z * es, true)
					continue
				var is_debug: bool = _debug_edge.size() == 3 and _debug_edge[0] == st.state_name \
						and _debug_edge[1] == t.event and _debug_edge[2] == t.to_state
				var hot: bool = is_debug or (not focus.is_empty() and (st.state_name == focus or t.to_state == focus))
				if (pass_i == 1) != hot:
					continue
				var col := DEBUG_COLOR if is_debug else _event_color(t.event)
				if not focus.is_empty() and not hot:
					col.a = 0.45
				var width := (3.0 if hot else 2.0) * z * es
				var tgn: GraphNode = _graph_nodes[t.to_state]
				_draw_link(_node_rect(gn), _row_y(gn, j), _node_rect(tgn), _title_y(tgn), col, width, gn == tgn)
	for state_name in globals:
		_draw_global_tag(_graph_nodes[state_name], ", ".join(globals[state_name]), z, es)
	_draw_link_drag(z, es)


## Vertical center (graph-local) of the event row of transition [param index].
func _row_y(gn: GraphNode, index: int) -> float:
	var row := gn.get_child(index) as Control
	if row == null:
		return _title_y(gn)
	return gn.position.y + (row.position.y + row.size.y * 0.5) * gn.scale.y


## Preview of the transition being dragged: to the hovered state, or to the mouse.
func _draw_link_drag(z: float, es: float) -> void:
	if _link_drag.is_empty() or not _graph_nodes.has(_link_drag.state):
		return
	var gn: GraphNode = _graph_nodes[_link_drag.state]
	var st := _fsm.get_state(_link_drag.state)
	if st == null or _link_drag.index >= st.transitions.size():
		return
	var col := _event_color(st.transitions[_link_drag.index].event)
	var width := 3.0 * z * es
	var y := _row_y(gn, _link_drag.index)
	var src := _node_rect(gn)
	if _graph_nodes.has(_link_hover):
		var tgn: GraphNode = _graph_nodes[_link_hover]
		_draw_link(src, y, _node_rect(tgn), _title_y(tgn), col, width, tgn == gn)
		return
	var mouse := _link_mouse
	var side := 1.0 if mouse.x >= src.get_center().x else -1.0
	var start := Vector2(src.end.x if side > 0 else src.position.x, y)
	var k := maxf(30.0 * z, absf(mouse.x - start.x) * 0.5)
	var pts := PackedVector2Array()
	for i in 25:
		pts.append(start.bezier_interpolate(start + Vector2(side * k, 0), mouse - Vector2(side * k * 0.3, 0), mouse, i / 24.0))
	col.a = 0.8
	_graph.draw_polyline(pts, col, width, true)
	_graph.draw_circle(start, maxf(width, 3.0 * z), col)
	_graph.draw_circle(mouse, 4.0 * z * es, col)


func _node_rect(gn: GraphNode) -> Rect2:
	return Rect2(gn.position, gn.size * gn.scale)


func _title_y(gn: GraphNode) -> float:
	var tb := gn.get_titlebar_hbox()
	return gn.position.y + (tb.position.y + tb.size.y * 0.5) * gn.scale.y


func _draw_link(src: Rect2, y: float, dst: Rect2, ty: float, col: Color, width: float, self_loop: bool) -> void:
	var z := _graph.zoom
	var margin := 24.0 * z
	# Try every combination of exit side (event row) and entry side (target title bar)
	# and keep the shortest natural route, like PlayMaker.
	var best_cost := INF
	var start := Vector2.ZERO
	var end := Vector2.ZERO
	var c1 := Vector2.ZERO
	var c2 := Vector2.ZERO
	var going_down := ty > y
	for exit_side in [1.0, -1.0]:
		for entry_side in [1.0, -1.0]:
			if self_loop and (exit_side < 0 or entry_side < 0):
				continue
			var sp := Vector2(src.end.x if exit_side > 0 else src.position.x, y)
			var ep := Vector2(dst.end.x if entry_side > 0 else dst.position.x, ty)
			var cost := 0.0
			var k1 := Vector2.ZERO
			var k2 := Vector2.ZERO
			if exit_side != entry_side:
				# S-curve: leave on one side, enter the opposite edge of the target.
				# Only natural when the target really lies on that side.
				if (ep.x - sp.x) * exit_side < margin:
					continue
				var k := maxf(margin * 1.5, absf(ep.x - sp.x) * 0.5)
				k1 = sp + Vector2(exit_side * k, 0)
				k2 = ep + Vector2(entry_side * k, 0)
				cost = sp.distance_to(ep)
			else:
				# Bracket: leave and enter on the same side.
				var edge := maxf(sp.x, ep.x) if exit_side > 0 else minf(sp.x, ep.x)
				var k := margin * 2.0 + absf(ep.y - sp.y) * 0.12
				k1 = Vector2(edge + exit_side * k, sp.y)
				k2 = Vector2(edge + exit_side * k, ep.y)
				cost = absf(ep.y - sp.y) + absf(ep.x - sp.x) + margin * 2.0
				# Same column: downward links on the right, upward links on the left,
				# so a pair of opposite transitions never overlaps.
				if (exit_side > 0) != going_down:
					cost += margin * 0.5
			if cost < best_cost:
				best_cost = cost
				start = sp
				end = ep
				c1 = k1
				c2 = k2
	var pts := PackedVector2Array()
	var steps := 32
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(start.bezier_interpolate(c1, c2, end, t))
	# Arrowhead along the curve's final direction; the line stops at its base.
	var ah := 10.0 * z * EditorInterface.get_editor_scale()
	var dir := (end - start.bezier_interpolate(c1, c2, end, 0.97)).normalized()
	if dir == Vector2.ZERO:
		dir = (end - c2).normalized()
	var base := end - dir * ah
	pts[pts.size() - 1] = base
	_graph.draw_polyline(pts, col, width, true)
	var perp := Vector2(-dir.y, dir.x) * ah * 0.5
	_graph.draw_colored_polygon(PackedVector2Array([end, base + perp, base - perp]), col)
	_graph.draw_circle(start, maxf(width, 3.0 * z), col)


## Global transition marker above a state (like PlayMaker's global transition box).
func _draw_global_tag(gn: GraphNode, text: String, z: float, es: float) -> void:
	var r := _node_rect(gn)
	var font := _graph.get_theme_default_font()
	var fs := maxi(6, int(11 * es * z))
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pad := 6.0 * z * es
	var box_h := fs + pad
	var gap := 18.0 * z * es
	var box := Rect2(Vector2(r.position.x, r.position.y - gap - box_h), Vector2(maxf(tw + pad * 2.0, 40.0 * z), box_h))
	var col := Color(1.0, 0.8, 0.4)
	_graph.draw_rect(box, Color(0.30, 0.24, 0.10, 0.95))
	_graph.draw_rect(box, col, false, maxf(1.0, z))
	_graph.draw_string(font, Vector2(box.position.x + pad, box.position.y + box_h * 0.5 + fs * 0.35), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	var from := Vector2(box.position.x + 14.0 * z * es, box.end.y)
	var to := Vector2(from.x, r.position.y)
	var ah := 7.0 * z * es
	_graph.draw_line(from, to - Vector2(0, ah), col, 2.0 * z * es, true)
	_graph.draw_colored_polygon(PackedVector2Array([to, to + Vector2(-ah * 0.6, -ah), to + Vector2(ah * 0.6, -ah)]), col)
#endregion


func _event_color(ev: String) -> Color:
	if ev == FINISHED:
		return Color(0.6, 0.9, 0.6)
	if _globals and _globals.events.has(ev):
		return Color(1.0, 0.8, 0.4)
	return Color(0.75, 0.85, 1.0)


func _style_graph_node(gn: GraphNode, st: RCState) -> void:
	var is_start := st.state_name == _fsm.start_state
	var is_debug := st.state_name == _debug_state
	gn.title = ("▶ " if is_start else "") + st.state_name
	var col := st.color
	if is_start:
		col = START_COLOR
	if is_debug:
		col = DEBUG_COLOR
	var s := EditorInterface.get_editor_scale()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = int(5 * s)
	sb.corner_radius_top_right = int(5 * s)
	sb.content_margin_left = 8 * s
	sb.content_margin_right = 8 * s
	sb.content_margin_top = 2 * s
	sb.content_margin_bottom = 2 * s
	if st.transitions.is_empty():
		sb.set_corner_radius_all(int(5 * s))
	gn.add_theme_stylebox_override("titlebar", sb)
	var sbs: StyleBoxFlat = sb.duplicate()
	sbs.bg_color = col.lightened(0.25)
	gn.add_theme_stylebox_override("titlebar_selected", sbs)
	for c in gn.get_titlebar_hbox().get_children():
		if c is Label:
			c.add_theme_color_override("font_color", Color.WHITE)
			c.add_theme_font_size_override("font_size", _graph_font_size())
			c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			c.size_flags_horizontal = SIZE_EXPAND_FILL
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.13, 0.13, 0.15, 0.95)
	panel.corner_radius_bottom_left = int(5 * s)
	panel.corner_radius_bottom_right = int(5 * s)
	panel.content_margin_left = 6 * s
	panel.content_margin_right = 6 * s
	panel.content_margin_top = 0 if st.transitions.is_empty() else 1 * s
	panel.content_margin_bottom = 0 if st.transitions.is_empty() else 3 * s
	var panel_sel: StyleBoxFlat = panel.duplicate()
	panel_sel.set_border_width_all(int(1 * s))
	panel_sel.border_color = Color(1, 1, 1, 0.6)
	if is_debug:
		panel.set_border_width_all(int(2 * s))
		panel.border_color = DEBUG_COLOR
		panel_sel = panel
	var level := _issue_level(st.state_name)
	if level > 0 and not is_debug:
		var ic: Color = ISSUE_COLORS[level]
		for box: StyleBoxFlat in [sb, sbs, panel, panel_sel]:
			box.set_border_width_all(int(2 * s))
			box.border_color = ic
		sb.border_width_bottom = 0
		sbs.border_width_bottom = 0
		panel.border_width_top = 0
		panel_sel.border_width_top = 0
		gn.title = "⚠ " + gn.title
	gn.add_theme_stylebox_override("panel", panel)
	gn.add_theme_stylebox_override("panel_selected", panel_sel)
	var tip := "%d action%s" % [st.actions.size(), "" if st.actions.size() == 1 else "s"]
	if st.sequence:
		tip += " (sequence)"
	if not st.description.is_empty():
		tip = st.description + "\n" + tip
	for issue in _issues.get("states", {}).get(st.state_name, []):
		tip += "\n⚠ " + issue[1]
	gn.tooltip_text = tip


## Denser variant of the editor theme (PlayMaker-like): slightly smaller font, thinner
## buttons and fields, less space between rows. Anything not set here falls back to the
## editor theme.
func _make_compact_theme() -> Theme:
	var et := EditorInterface.get_editor_theme()
	var s := EditorInterface.get_editor_scale()
	var t := Theme.new()
	t.default_font_size = maxi(10, roundi(_editor_font_size() * 0.9))
	for type in ["VBoxContainer", "HBoxContainer"]:
		t.set_constant("separation", type, roundi(2 * s))
	for type in ["Label", "Button", "LineEdit", "OptionButton", "MenuButton", "CheckBox", "CheckButton",
			"ColorPickerButton", "TextEdit", "TabContainer", "TabBar"]:
		for sb_name in et.get_stylebox_list(type):
			var sb := et.get_stylebox(sb_name, type).duplicate() as StyleBox
			if sb.content_margin_top > 2 * s:
				sb.content_margin_top = 2 * s
			if sb.content_margin_bottom > 2 * s:
				sb.content_margin_bottom = 2 * s
			t.set_stylebox(sb_name, type, sb)
	return t


## Font size of state titles and event rows in the graph (a bit smaller than the editor's).
func _graph_font_size() -> int:
	return maxi(10, roundi(_editor_font_size() * 0.9))


func _editor_font_size() -> int:
	var fs := EditorInterface.get_editor_theme().default_font_size
	return fs if fs > 0 else roundi(14 * EditorInterface.get_editor_scale())


func _restyle_graph() -> void:
	if _fsm == null:
		return
	for n in _graph_nodes:
		var st := _fsm.get_state(n)
		if st:
			_style_graph_node(_graph_nodes[n], st)
	_graph.queue_redraw()


func _state_of(graph_node_name: StringName) -> String:
	return _node_to_state.get(String(graph_node_name), "")


func _on_node_selected(node: Node) -> void:
	var n := _state_of(node.name)
	if n.is_empty() or n == _selected_state:
		return
	_selected_state = n
	_rebuild_state_panel()
	_tabs.current_tab = 0
	_graph.queue_redraw()


func _on_end_node_move() -> void:
	modify("Move States", func() -> void:
		for n in _graph_nodes:
			var st := _fsm.get_state(n)
			if st:
				st.position = _graph_nodes[n].position_offset
		_store_frame_rects()
	, false, false)


#region Connecting transitions (PlayMaker-style drag from the event row)
func _on_transition_row_input(ev: InputEvent, state_name: String, index: int) -> void:
	if not ev is InputEventMouseButton or not ev.pressed:
		return
	if ev.button_index == MOUSE_BUTTON_LEFT:
		_link_drag = {"state": state_name, "index": index}
		_link_hover = ""
		_link_mouse = _graph.get_local_mouse_position()
		if _graph_nodes.has(state_name):
			_graph.set_selected(_graph_nodes[state_name])
		get_viewport().set_input_as_handled()
		_graph.queue_redraw()
	elif ev.button_index == MOUSE_BUTTON_RIGHT:
		_menu_transition = {"state": state_name, "index": index}
		_show_transition_menu()
		get_viewport().set_input_as_handled()


func _input(ev: InputEvent) -> void:
	if _link_drag.is_empty():
		return
	if ev is InputEventMouse:
		_link_mouse = _graph.get_global_transform_with_canvas().affine_inverse() * ev.position
	if ev is InputEventMouseMotion:
		_set_link_hover(_state_at(_link_mouse))
		_graph.queue_redraw()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
		_set_link_hover(_state_at(_link_mouse))
		var drag := _link_drag
		var target := _link_hover
		_end_link_drag()
		get_viewport().set_input_as_handled()
		if not target.is_empty():
			_connect_transition(drag.state, drag.index, target)
	elif ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_end_link_drag()
		get_viewport().set_input_as_handled()


## State whose node is at a graph-local position (topmost), or "".
func _state_at(mouse: Vector2) -> String:
	if not Rect2(Vector2.ZERO, _graph.size).has_point(mouse):
		return ""
	var found := ""
	for c in _graph.get_children():
		if c is GraphNode and _node_rect(c).grow(4.0).has_point(mouse):
			found = _state_of(c.name)
	return found


func _set_link_hover(state_name: String) -> void:
	if state_name == _link_hover:
		return
	if _graph_nodes.has(_link_hover):
		_graph_nodes[_link_hover].modulate = Color.WHITE
	_link_hover = state_name
	if _graph_nodes.has(_link_hover):
		_graph_nodes[_link_hover].modulate = Color(1.25, 1.35, 1.6)


func _end_link_drag() -> void:
	_set_link_hover("")
	_link_drag = {}
	_graph.queue_redraw()


func _connect_transition(state_name: String, index: int, target: String) -> void:
	var st := _fsm.get_state(state_name)
	if st == null or index >= st.transitions.size() or st.transitions[index].to_state == target:
		return
	var t := st.transitions[index]
	modify("Connect Transition", func() -> void: t.to_state = target)


func _show_transition_menu() -> void:
	var st := _fsm.get_state(_menu_transition.get("state", ""))
	if st == null or _menu_transition.index >= st.transitions.size():
		return
	var t := st.transitions[_menu_transition.index]
	_transition_menu.clear()
	_transition_event_sub.clear()
	var events := get_event_items()
	for i in events.size():
		_transition_event_sub.add_radio_check_item(events[i], i)
		_transition_event_sub.set_item_checked(i, events[i] == t.event)
	_transition_menu.add_submenu_node_item("Event", _transition_event_sub)
	_transition_menu.add_item("Disconnect", 1)
	_transition_menu.set_item_disabled(_transition_menu.item_count - 1, t.to_state.is_empty())
	_transition_menu.add_separator()
	_transition_menu.add_item("Move Up", 2)
	_transition_menu.set_item_disabled(_transition_menu.item_count - 1, _menu_transition.index == 0)
	_transition_menu.add_item("Move Down", 3)
	_transition_menu.set_item_disabled(_transition_menu.item_count - 1, _menu_transition.index >= st.transitions.size() - 1)
	_transition_menu.add_separator()
	_transition_menu.add_item("Delete Transition", 4)
	_popup_at_mouse(_transition_menu)


func _on_transition_menu(id: int) -> void:
	var st := _fsm.get_state(_menu_transition.get("state", ""))
	var i: int = _menu_transition.get("index", -1)
	if st == null or i < 0 or i >= st.transitions.size():
		return
	var t := st.transitions[i]
	match id:
		1:
			modify("Disconnect Transition", func() -> void: t.to_state = "")
		2:
			modify("Move Transition", func() -> void:
				st.transitions.remove_at(i)
				st.transitions.insert(i - 1, t)
			)
		3:
			modify("Move Transition", func() -> void:
				st.transitions.remove_at(i)
				st.transitions.insert(i + 1, t)
			)
		4:
			modify("Delete Transition", func() -> void: st.transitions.remove_at(i))


func _on_transition_event_chosen(id: int) -> void:
	var st := _fsm.get_state(_menu_transition.get("state", ""))
	var i: int = _menu_transition.get("index", -1)
	if st == null or i < 0 or i >= st.transitions.size():
		return
	var ev := _transition_event_sub.get_item_text(_transition_event_sub.get_item_index(id))
	var t := st.transitions[i]
	modify("Set Transition Event", func() -> void:
		t.event = ev
		_ensure_event(ev)
	)
#endregion


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	var names: Array[String] = []
	var groups: Array[RCGroup] = []
	for n in nodes:
		var s := _state_of(n)
		if not s.is_empty():
			names.append(s)
		elif _frame_to_group.has(String(n)):
			groups.append(_fsm.groups[_frame_to_group[String(n)]])
	if names.is_empty() and groups.is_empty():
		return
	modify("Delete", func() -> void:
		for g in groups:
			_fsm.groups.erase(g)
		_delete_states(names)
	)


func _delete_states(names: Array[String]) -> void:
	for n in names:
		var st := _fsm.get_state(n)
		if st:
			_fsm.states.erase(st)
	for st in _fsm.states:
		for t in st.transitions:
			if names.has(t.to_state):
				t.to_state = ""
	var keep: Array[RCTransition] = []
	for gt in _fsm.global_transitions:
		if not names.has(gt.to_state):
			keep.append(gt)
	_fsm.global_transitions = keep
	if names.has(_fsm.start_state):
		_fsm.start_state = _fsm.states[0].state_name if not _fsm.states.is_empty() else ""
	for g: RCGroup in _fsm.groups.duplicate():
		if g.is_comment():
			continue
		for n in names:
			var i := g.states.find(n)
			if i >= 0:
				g.states.remove_at(i)
		# A group whose states are all gone disappears (it must not turn into a comment).
		if g.states.is_empty():
			_fsm.groups.erase(g)


func _selected_state_names() -> Array[String]:
	var out: Array[String] = []
	for n in _graph_nodes:
		if _graph_nodes[n].selected:
			out.append(n)
	return out


func _on_duplicate_nodes_request() -> void:
	_on_copy_nodes_request()
	_on_paste_nodes_request()


func _on_copy_nodes_request() -> void:
	_clipboard.clear()
	for n in _selected_state_names():
		_clipboard.append(RCFsm.clone_state(_fsm.get_state(n)))


func _on_paste_nodes_request() -> void:
	if _clipboard.is_empty() or _fsm == null:
		return
	var clips := _clipboard.duplicate()
	modify("Paste States", func() -> void:
		var renames := {}
		for c in clips:
			var ns := RCFsm.clone_state(c)
			ns.state_name = _fsm.unique_state_name(c.state_name)
			ns.position += Vector2(40, 40)
			renames[c.state_name] = ns.state_name
			_fsm.states.append(ns)
		# Transitions between pasted states point to the pasted copies.
		for c in clips:
			var ns := _fsm.get_state(renames[c.state_name])
			for t in ns.transitions:
				if renames.has(t.to_state):
					t.to_state = renames[t.to_state]
	)
	_selected_state = _fsm.states[-1].state_name


func _on_graph_popup_request(at_position: Vector2) -> void:
	_menu_pos = (at_position + _graph.scroll_offset) / _graph.zoom
	_graph_menu.clear()
	_graph_menu.add_item("Add State", MENU_ADD_STATE)
	_graph_menu.add_item("Paste State(s)", MENU_PASTE)
	_graph_menu.set_item_disabled(1, _clipboard.is_empty())
	_graph_menu.add_separator()
	_graph_menu.add_item("Add Comment", MENU_ADD_COMMENT)
	if _selected_state_names().size() > 0:
		_graph_menu.add_item("Group Selected States", MENU_GROUP)
	_popup_at_mouse(_graph_menu)


func _on_graph_menu(id: int) -> void:
	match id:
		MENU_ADD_STATE:
			_add_state(_menu_pos)
		MENU_PASTE:
			_on_paste_nodes_request()
		MENU_ADD_COMMENT:
			_add_comment(_menu_pos)
		MENU_GROUP:
			_group_states(_selected_state_names())


func _on_graph_node_gui_input(ev: InputEvent, state_name: String) -> void:
	if not ev is InputEventMouseButton or not ev.pressed:
		return
	# The whole area below the title bar belongs to the event rows (including the side
	# margins), so a slightly missed row starts a link instead of moving the node.
	# The node is moved by its title bar.
	if _graph_nodes.has(state_name):
		var row := _transition_row_at(_graph_nodes[state_name], ev.position.y)
		if row >= 0:
			_on_transition_row_input(ev, state_name, row)
			return
	if ev.button_index == MOUSE_BUTTON_RIGHT:
		_menu_state = state_name
		if _graph_nodes.has(state_name):
			_graph.set_selected(_graph_nodes[state_name])
		_show_node_menu()
		get_viewport().set_input_as_handled()


## Index of the event row nearest to [param y] (GraphNode-local), or -1 on the title bar.
func _transition_row_at(gn: GraphNode, y: float) -> int:
	if gn.get_child_count() == 0:
		return -1
	var tb := gn.get_titlebar_hbox()
	if y <= tb.position.y + tb.size.y:
		return -1
	var best := -1
	var best_dist := INF
	for i in gn.get_child_count():
		var row := gn.get_child(i) as Control
		var dist := absf(y - (row.position.y + row.size.y * 0.5))
		if dist < best_dist:
			best = i
			best_dist = dist
	return best


func _show_node_menu() -> void:
	_node_menu.clear()
	_transition_sub.clear()
	_global_sub.clear()
	var events := get_event_items()
	for i in events.size():
		_transition_sub.add_item(events[i], i)
		_global_sub.add_item(events[i], i)
	_node_menu.add_item("Set as Start State", MENU_SET_START)
	_node_menu.set_item_disabled(0, _menu_state == _fsm.start_state)
	_node_menu.add_submenu_node_item("Add Transition", _transition_sub)
	_node_menu.add_submenu_node_item("Add Global Transition (to this state)", _global_sub)
	_node_menu.add_separator()
	_node_menu.add_item("Copy", MENU_COPY)
	_node_menu.add_item("Duplicate", MENU_DUPLICATE)
	_node_menu.add_item("Delete", MENU_DELETE)
	_node_menu.add_separator()
	var sel := _selected_state_names()
	_node_menu.add_item("Group Selected States" if sel.size() > 1 else "Put in a Group", MENU_GROUP)
	if _group_of_state(_menu_state) >= 0:
		_node_menu.add_item("Remove from Group", MENU_UNGROUP_STATE)
	_popup_at_mouse(_node_menu)


func _on_node_menu(id: int) -> void:
	match id:
		MENU_SET_START:
			var n := _menu_state
			modify("Set Start State", func() -> void: _fsm.start_state = n)
		MENU_COPY:
			_on_copy_nodes_request()
		MENU_DUPLICATE:
			_on_duplicate_nodes_request()
		MENU_DELETE:
			var names: Array[String] = [_menu_state]
			modify("Delete State", func() -> void: _delete_states(names))
		MENU_GROUP:
			var sel := _selected_state_names()
			if not sel.has(_menu_state):
				sel.clear()
				sel.append(_menu_state)
			_group_states(sel)
		MENU_UNGROUP_STATE:
			var one: Array[String] = [_menu_state]
			modify("Remove from Group", func() -> void: _remove_from_groups(one))


func _popup_at_mouse(menu: PopupMenu) -> void:
	menu.reset_size()
	menu.position = Vector2i(get_screen_position() + get_local_mouse_position())
	menu.popup()


func _make_state(state_name: String, pos: Vector2) -> RCState:
	var st := RCState.new()
	st.state_name = state_name
	st.position = pos
	return st


func _add_state(pos: Vector2) -> void:
	if _fsm == null:
		return
	var n := _fsm.unique_state_name()
	modify("Add State", func() -> void:
		_fsm.states.append(_make_state(n, pos))
		if _fsm.start_state.is_empty():
			_fsm.start_state = n
	)
	_selected_state = n


func _add_transition(state_name: String, ev: String) -> void:
	var st := _fsm.get_state(state_name)
	if st == null:
		return
	modify("Add Transition", func() -> void:
		st.transitions.append(RCTransition.make(ev))
		_ensure_event(ev)
	)


func _add_global_transition(ev: String, to_state: String) -> void:
	modify("Add Global Transition", func() -> void:
		_fsm.global_transitions.append(RCTransition.make(ev, to_state))
		_ensure_event(ev)
	)
#endregion


#region Context for property rows
func get_owner_node() -> Node:
	if _node and is_instance_valid(_node) and _node.is_inside_tree():
		return _node.get_node_or_null(_node.owner_path)
	return null


## Shows a "New Variable" dialog. [param on_created] receives the variable reference
## ("name" for a local variable, "g:name" for a global one) after it was created.
func prompt_new_variable(suggested_name: String, suggested_type: int, on_created: Callable) -> void:
	if _fsm == null:
		return
	var es := EditorInterface.get_editor_scale()
	var d := ConfirmationDialog.new()
	d.title = "New Variable"
	d.ok_button_text = "Create"
	d.dialog_hide_on_ok = false
	var vb := VBoxContainer.new()
	vb.custom_minimum_size.x = 320 * es
	d.add_child(vb)
	var grid := GridContainer.new()
	grid.columns = 2
	vb.add_child(grid)
	var nl := Label.new()
	nl.text = "Name"
	grid.add_child(nl)
	var name_edit := LineEdit.new()
	name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	var base := suggested_name.strip_edges().to_snake_case().replace(" ", "_")
	if not base.is_valid_identifier():
		base = "variable"
	name_edit.text = base if _fsm.get_variable(base) == null else _fsm.unique_variable_name(base)
	grid.add_child(name_edit)
	var tl := Label.new()
	tl.text = "Type"
	grid.add_child(tl)
	var type_btn := OptionButton.new()
	for t in RCVariable.TYPES:
		type_btn.add_item(RCVariable.type_label(t), t)
	type_btn.select(maxi(0, type_btn.get_item_index(suggested_type)))
	grid.add_child(type_btn)
	var global_cb := CheckBox.new()
	global_cb.text = "Global (shared by all FSMs)"
	vb.add_child(global_cb)
	var err := Label.new()
	err.add_theme_color_override("font_color", Color(1, 0.45, 0.4))
	err.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(err)
	var create := func() -> void:
		var n := name_edit.text.strip_edges().replace(" ", "_")
		var is_global := global_cb.button_pressed
		var source: Resource = _globals if is_global else _fsm
		if not n.is_valid_identifier():
			err.text = "Use letters, digits and _ (cannot start with a digit)."
			return
		if source.get_variable(n) != null:
			err.text = "A %s variable named '%s' already exists." % ["global" if is_global else "local", n]
			return
		var t := type_btn.get_selected_id()
		modify_variables(source, "Add Variable", func() -> void:
			var nv := RCVariable.new()
			nv.name = n
			nv.type = t
			source.variables.append(nv)
		)
		d.hide()
		d.queue_free()
		on_created.call(("g:" + n) if is_global else n)
	d.confirmed.connect(create)
	name_edit.text_submitted.connect(func(_t: String) -> void: create.call())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered()
	name_edit.select_all()
	name_edit.grab_focus.call_deferred()


## [{name, type, label}] of local and global variables.
func get_variable_infos() -> Array:
	var out: Array = []
	if _fsm:
		for v in _fsm.variables:
			if v:
				out.append({"name": v.name, "type": v.type, "label": "%s : %s" % [v.name, RCVariable.type_label(v.type)]})
	if _globals:
		for v in _globals.variables:
			if v:
				out.append({"name": "g:" + v.name, "type": v.type, "label": "★ %s : %s (global)" % [v.name, RCVariable.type_label(v.type)]})
	return out


## Signals of the node an action works on, for "signal_name" fields:
## [{name, label}] - the node's script signals first, then the built-in class signals
## (most specific class first).
## The node is the one in the action's "source" property (Connect Signal) or "target".
func get_signal_items(action: Object, _prop: String) -> Array:
	var out: Array = []
	var node := _resolve_action_node(action, "source" if "source" in action else "target")
	if node == null:
		return out
	var seen := {}
	var script_signals: Array = []
	var s: Script = node.get_script()
	while s:
		script_signals.append_array(s.get_script_signal_list())
		s = s.get_base_script()
	# Built-in signals from the most specific class up (Area2D before CollisionObject2D ... Object).
	var class_signals: Array = []
	var cls := node.get_class()
	while not cls.is_empty():
		class_signals.append_array(ClassDB.class_get_signal_list(cls, true))
		cls = ClassDB.get_parent_class(cls)
	for list in [script_signals, class_signals]:
		for sig in list:
			var n: String = sig.name
			if seen.has(n):
				continue
			seen[n] = true
			var args := PackedStringArray()
			for arg in sig.args:
				var t: String = arg.class_name if not String(arg.class_name).is_empty() else (type_string(arg.type) if arg.type != TYPE_NIL else "Variant")
				args.append("%s: %s" % [arg.name, t])
			out.append({"name": n, "label": "%s(%s)" % [n, ", ".join(args)]})
	return out


## Node a NodePath property of an action points to, inside the edited scene (null if unknown).
func _resolve_action_node(action: Object, prop: String) -> Node:
	var o := get_owner_node()
	if o == null or action == null or not prop in action:
		return null
	if action is RCAction and action.bindings.has(prop):
		return null
	var path: Variant = action.get(prop)
	if not path is NodePath or path.is_empty():
		return o
	return o.get_node_or_null(path)


func get_event_items() -> PackedStringArray:
	var out := PackedStringArray([FINISHED])
	if _fsm:
		for e in _fsm.events:
			if not out.has(e):
				out.append(e)
	if _globals:
		for e in _globals.events:
			if not out.has(e):
				out.append(e)
	return out


func get_input_actions() -> PackedStringArray:
	var out := PackedStringArray()
	for p in ProjectSettings.get_property_list():
		var n: String = p.name
		if n.begins_with("input/"):
			out.append(n.substr(6))
	out.sort()
	return out


func _ensure_event(ev: String) -> void:
	if ev.is_empty() or ev == FINISHED or _fsm.events.has(ev):
		return
	if _globals and _globals.events.has(ev):
		return
	_fsm.events = _fsm.events + PackedStringArray([ev])


func _is_event_known(ev: String) -> bool:
	return ev.is_empty() or get_event_items().has(ev)


func set_action_property(a: RCAction, prop: String, value: Variant) -> void:
	var cur: Variant = a.get(prop)
	if typeof(cur) == typeof(value) and cur == value:
		return
	var needs_event := PropertyRow.is_event_property(prop) and value is String and not _is_event_known(value)
	# A new target node changes the lists offered by other fields (e.g. its signals).
	var rebuild := needs_event or value is NodePath
	modify("Set %s.%s" % [a.get_title(), prop], func() -> void:
		a.set(prop, value)
		if needs_event:
			_ensure_event(value)
	, not rebuild, rebuild)


func set_action_binding(a: RCAction, prop: String, var_name: String) -> void:
	modify("Bind %s.%s" % [a.get_title(), prop], func() -> void:
		var b := a.bindings.duplicate()
		if var_name.is_empty():
			b.erase(prop)
		else:
			b[prop] = var_name
		a.bindings = b
	)
#endregion


#region State panel
func _section(parent: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	parent.add_child(HSeparator.new())
	parent.add_child(l)


func _rebuild_state_panel() -> void:
	_clear_children(_state_box)
	_issues_box = null
	var st := _fsm.get_state(_selected_state) if _fsm else null
	if st == null:
		var l := Label.new()
		l.text = "Select a state in the graph.\nRight-click the graph to add states, drag an event row onto a state to connect it."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_state_box.add_child(l)
		return
	var et := EditorInterface.get_editor_theme()
	# Name
	var name_row := HBoxContainer.new()
	var nl := Label.new()
	nl.text = "State"
	name_row.add_child(nl)
	var name_edit := LineEdit.new()
	name_edit.text = st.state_name
	name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	var rename := func() -> void: _rename_state(st.state_name, name_edit.text)
	name_edit.text_submitted.connect(func(_t: String) -> void: rename.call())
	name_edit.focus_exited.connect(rename)
	name_row.add_child(name_edit)
	var cp := ColorPickerButton.new()
	cp.color = st.color
	cp.custom_minimum_size = Vector2(32, 0) * EditorInterface.get_editor_scale()
	cp.tooltip_text = "State color"
	cp.get_picker().presets_visible = true
	for c in STATE_COLORS:
		cp.get_picker().add_preset(c)
	cp.color_changed.connect(func(c: Color) -> void:
		modify("Set State Color", func() -> void: st.color = c, true, false)
		_restyle_graph()
	)
	name_row.add_child(cp)
	_state_box.add_child(name_row)
	var opts := HBoxContainer.new()
	var start_btn := Button.new()
	start_btn.text = "Start State" if st.state_name == _fsm.start_state else "Set as Start State"
	start_btn.disabled = st.state_name == _fsm.start_state
	start_btn.pressed.connect(func() -> void:
		var n := st.state_name
		modify("Set Start State", func() -> void: _fsm.start_state = n)
	)
	opts.add_child(start_btn)
	var seq := CheckBox.new()
	seq.text = "Sequence"
	seq.tooltip_text = "Run actions one after another (each starts when the previous one finished)."
	seq.button_pressed = st.sequence
	seq.toggled.connect(func(p: bool) -> void: modify("Toggle Sequence", func() -> void: st.sequence = p))
	opts.add_child(seq)
	_state_box.add_child(opts)
	var desc := TextEdit.new()
	desc.placeholder_text = "Description…"
	desc.text = st.description
	desc.custom_minimum_size.y = 40 * EditorInterface.get_editor_scale()
	desc.scroll_fit_content_height = true
	desc.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	desc.text_changed.connect(func() -> void:
		var t := desc.text
		modify("Set State Description", func() -> void: st.description = t, true, false)
	)
	_state_box.add_child(desc)
	_issues_box = VBoxContainer.new()
	_state_box.add_child(_issues_box)
	_fill_issues_box()

	# Transitions
	_section(_state_box, "Transitions (event → state)")
	for i in st.transitions.size():
		_state_box.add_child(_make_transition_row(st, i, et))
	var add_tr := Button.new()
	add_tr.text = "Add Transition"
	add_tr.icon = et.get_icon("Add", "EditorIcons")
	add_tr.pressed.connect(func() -> void:
		var ev := FINISHED if st.get_transition(FINISHED) == null else ""
		_add_transition(st.state_name, ev)
	)
	_state_box.add_child(add_tr)

	# Actions
	_section(_state_box, "Actions")
	if st.actions.size() > 1:
		var fold := HBoxContainer.new()
		for expand in [false, true]:
			var fb := Button.new()
			fb.text = "Expand All" if expand else "Collapse All"
			fb.flat = true
			fb.icon = et.get_icon("GuiTreeArrowDown" if expand else "GuiTreeArrowRight", "EditorIcons")
			fb.pressed.connect(func() -> void:
				for a in st.actions:
					if a:
						a.editor_collapsed = not expand
				_rebuild_state_panel()
			)
			fold.add_child(fb)
		_state_box.add_child(fold)
	if st.actions.is_empty():
		var l := Label.new()
		l.text = "No actions. A state without actions sends FINISHED immediately."
		l.modulate = Color(1, 1, 1, 0.6)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_state_box.add_child(l)
	for i in st.actions.size():
		if st.actions[i] != null:
			_state_box.add_child(_make_action_panel(st, i, et))
	var add_act := Button.new()
	add_act.text = "Add Action…"
	add_act.icon = et.get_icon("Add", "EditorIcons")
	add_act.pressed.connect(func() -> void: _browser.popup_browser())
	_state_box.add_child(add_act)


func _make_transition_row(st: RCState, i: int, et: Theme) -> HBoxContainer:
	var t := st.transitions[i]
	var row := HBoxContainer.new()
	var combo := PropertyRow.make_combo(t.event, get_event_items(), func(s: String) -> void:
		if s == t.event:
			return
		modify("Set Transition Event", func() -> void:
			t.event = s
			_ensure_event(s)
		)
	, "(event)")
	row.add_child(combo)
	var arrow := Label.new()
	arrow.text = "→"
	row.add_child(arrow)
	var ob := OptionButton.new()
	ob.add_item("(none)", 0)
	var names: Array[String] = []
	for s in _fsm.states:
		names.append(s.state_name)
		ob.add_item(s.state_name, names.size())
		if s.state_name == t.to_state:
			ob.select(ob.item_count - 1)
	ob.size_flags_horizontal = SIZE_EXPAND_FILL
	ob.clip_text = true
	ob.item_selected.connect(func(idx: int) -> void:
		var target := "" if idx == 0 else names[idx - 1]
		modify("Set Transition Target", func() -> void: t.to_state = target)
	)
	row.add_child(ob)
	row.add_child(_icon_button(et, "MoveUp", "Move up", i > 0, func() -> void:
		modify("Move Transition", func() -> void:
			st.transitions.remove_at(i)
			st.transitions.insert(i - 1, t)
		)
	))
	row.add_child(_icon_button(et, "MoveDown", "Move down", i < st.transitions.size() - 1, func() -> void:
		modify("Move Transition", func() -> void:
			st.transitions.remove_at(i)
			st.transitions.insert(i + 1, t)
		)
	))
	row.add_child(_icon_button(et, "Remove", "Delete transition", true, func() -> void:
		modify("Delete Transition", func() -> void: st.transitions.remove_at(i))
	))
	return row


func _icon_button(et: Theme, icon: String, tip: String, enabled: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.icon = et.get_icon(icon, "EditorIcons")
	b.tooltip_text = tip
	b.flat = true
	b.disabled = not enabled
	b.pressed.connect(cb)
	return b


func _make_action_panel(st: RCState, i: int, et: Theme) -> PanelContainer:
	var a := st.actions[i]
	var s := EditorInterface.get_editor_scale()
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.18) if a.enabled else Color(0, 0, 0, 0.08)
	sb.border_color = Color(1, 0.84, 0.5, 0.35)
	sb.border_width_left = int(3 * s)
	sb.set_corner_radius_all(int(4 * s))
	sb.set_content_margin_all(4 * s)
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var header := HBoxContainer.new()
	vb.add_child(header)
	var en := CheckBox.new()
	en.button_pressed = a.enabled
	en.tooltip_text = "Enabled"
	en.toggled.connect(func(p: bool) -> void: modify("Toggle Action", func() -> void: a.enabled = p))
	header.add_child(en)
	var collapsed := a.editor_collapsed
	var title_btn := Button.new()
	title_btn.text = ("▸ " if collapsed else "▾ ") + a.get_title()
	title_btn.flat = true
	title_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_btn.tooltip_text = RCAction.description_for_script(a.get_script())
	if not a.enabled:
		title_btn.modulate = Color(1, 1, 1, 0.5)
	header.add_child(title_btn)
	# Parameter summary, visible while the action is folded. Clicking it unfolds the action.
	var summary := Label.new()
	summary.size_flags_horizontal = SIZE_EXPAND_FILL
	summary.clip_text = true
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	summary.modulate = Color(1, 1, 1, 0.5)
	summary.mouse_filter = Control.MOUSE_FILTER_STOP
	summary.text = _action_summary(a) if collapsed else ""
	summary.tooltip_text = summary.text
	header.add_child(summary)
	header.add_child(_icon_button(et, "MoveUp", "Move up", i > 0, func() -> void:
		modify("Move Action", func() -> void:
			st.actions.remove_at(i)
			st.actions.insert(i - 1, a)
		)
	))
	header.add_child(_icon_button(et, "MoveDown", "Move down", i < st.actions.size() - 1, func() -> void:
		modify("Move Action", func() -> void:
			st.actions.remove_at(i)
			st.actions.insert(i + 1, a)
		)
	))
	header.add_child(_icon_button(et, "Duplicate", "Duplicate action", true, func() -> void:
		modify("Duplicate Action", func() -> void: st.actions.insert(i + 1, RCFsm.clone_resource(a) as RCAction))
	))
	header.add_child(_icon_button(et, "Edit", "Open script", true, func() -> void:
		EditorInterface.edit_script(a.get_script())
		EditorInterface.set_main_screen_editor("Script")
	))
	header.add_child(_icon_button(et, "Remove", "Delete action", true, func() -> void:
		modify("Delete Action", func() -> void: st.actions.remove_at(i))
	))
	var body := VBoxContainer.new()
	body.visible = not collapsed
	vb.add_child(body)
	var toggle := func() -> void:
		var c := not a.editor_collapsed
		a.editor_collapsed = c
		body.visible = not c
		title_btn.text = ("▸ " if c else "▾ ") + a.get_title()
		summary.text = _action_summary(a) if c else ""
		summary.tooltip_text = summary.text
	title_btn.pressed.connect(toggle)
	summary.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			toggle.call()
	)
	var props := _action_properties(a)
	if props.is_empty():
		var l := Label.new()
		l.text = "(no parameters)"
		l.modulate = Color(1, 1, 1, 0.5)
		body.add_child(l)
	for p in props:
		if p.usage & (PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP):
			var gl := Label.new()
			gl.text = p.name
			gl.modulate = Color(0.7, 0.85, 1, 0.8)
			body.add_child(gl)
			continue
		var row := PropertyRow.new()
		row.setup(self, a, p,
				func(prop: String, v: Variant) -> void: set_action_property(a, prop, v),
				func(prop: String, vn: String) -> void: set_action_binding(a, prop, vn),
				str(a.bindings.get(p.name, "")))
		body.add_child(row)
	return panel


## Short one-line description of an action's parameters, e.g. "time 1.5 · finish_event GO".
func _action_summary(a: RCAction) -> String:
	var parts := PackedStringArray()
	for p in _action_properties(a):
		if p.usage & (PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP):
			continue
		var n: String = p.name
		if a.bindings.has(n):
			parts.append("%s ⇢ %s" % [n, a.bindings[n]])
			continue
		var v: Variant = a.get(n)
		var def: Variant = a.get_script().get_property_default_value(n)
		if typeof(def) == typeof(v) and def == v:
			continue
		var txt := ""
		match typeof(v):
			TYPE_BOOL:
				if v:
					txt = n
			TYPE_INT:
				if p.get("hint", 0) == PROPERTY_HINT_ENUM:
					var next := 0
					for item in str(p.get("hint_string", "")).split(","):
						var label := item
						var value := next
						if item.contains(":"):
							label = item.get_slice(":", 0)
							value = item.get_slice(":", 1).to_int()
						if value == v:
							txt = "%s %s" % [n, label.strip_edges()]
							break
						next = value + 1
				else:
					txt = "%s %d" % [n, v]
			TYPE_FLOAT:
				txt = "%s %s" % [n, str(snappedf(v, 0.001))]
			TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
				if not str(v).is_empty():
					txt = "%s %s" % [n, str(v).replace("\n", " ")]
			TYPE_OBJECT:
				if v is Resource and not v.resource_path.is_empty():
					txt = "%s %s" % [n, v.resource_path.get_file()]
			TYPE_PACKED_STRING_ARRAY:
				if not v.is_empty():
					txt = "%s [%s]" % [n, ", ".join(v)]
			TYPE_NIL:
				pass
			_:
				txt = "%s %s" % [n, str(v)]
		if not txt.is_empty():
			parts.append(txt)
	return " · ".join(parts)


func _action_properties(a: RCAction) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var script: Script = a.get_script()
	if script == null:
		return out
	for p in script.get_script_property_list():
		var usage: int = p.usage
		if usage & PROPERTY_USAGE_CATEGORY:
			continue
		if usage & (PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP):
			out.append(p)
			continue
		if not usage & PROPERTY_USAGE_EDITOR:
			continue
		if p.name in ["enabled", "bindings", "script"]:
			continue
		out.append(p)
	return out


func _on_action_chosen(script: Script) -> void:
	var st := _fsm.get_state(_selected_state) if _fsm else null
	if st == null:
		return
	modify("Add Action", func() -> void:
		var a: RCAction = script.new()
		st.actions.append(a)
	)


func _rename_state(old_name: String, new_name: String) -> void:
	new_name = new_name.strip_edges()
	if new_name == old_name or new_name.is_empty():
		return
	if _fsm.get_state(new_name) != null:
		push_warning("RunCrafter: a state named '%s' already exists." % new_name)
		queue_refresh()
		return
	modify("Rename State", func() -> void:
		_fsm.get_state(old_name).state_name = new_name
		for s in _fsm.states:
			for t in s.transitions:
				if t.to_state == old_name:
					t.to_state = new_name
		for t in _fsm.global_transitions:
			if t.to_state == old_name:
				t.to_state = new_name
		if _fsm.start_state == old_name:
			_fsm.start_state = new_name
		for g in _fsm.groups:
			var i := g.states.find(old_name)
			if i >= 0:
				g.states[i] = new_name
	)
	_selected_state = new_name
#endregion


#region Events panel
func _rebuild_events_panel() -> void:
	_clear_children(_events_box)
	var et := EditorInterface.get_editor_theme()
	var help := Label.new()
	help.text = "Events trigger transitions. FINISHED is sent automatically when all actions of a state have finished. Global events (Globals tab) can be used by every FSM."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.modulate = Color(1, 1, 1, 0.6)
	_events_box.add_child(help)
	var fin := Label.new()
	fin.text = "FINISHED   (system)"
	fin.modulate = Color(0.6, 0.9, 0.6)
	_events_box.add_child(fin)
	var usage := _event_usage()
	for i in _fsm.events.size():
		var ev := _fsm.events[i]
		var row := HBoxContainer.new()
		var le := LineEdit.new()
		le.text = ev
		le.size_flags_horizontal = SIZE_EXPAND_FILL
		var commit := func() -> void: _rename_event(ev, le.text.strip_edges())
		le.text_submitted.connect(func(_t: String) -> void: commit.call())
		le.focus_exited.connect(commit)
		row.add_child(le)
		var ul := Label.new()
		ul.text = "used %d×" % usage.get(ev, 0)
		ul.modulate = Color(1, 1, 1, 0.5)
		row.add_child(ul)
		var to_global := _icon_button(et, "ArrowUp", "Make global event", true, func() -> void:
			if not _globals.events.has(ev):
				_globals.events = _globals.events + PackedStringArray([ev])
				_globals_save_timer.start()
			modify("Make Event Global", func() -> void: _remove_event(ev))
		)
		row.add_child(to_global)
		row.add_child(_icon_button(et, "Remove", "Delete event (transitions using it are kept)", true, func() -> void:
			modify("Delete Event", func() -> void: _remove_event(ev))
		))
		_events_box.add_child(row)
	_events_box.add_child(_make_add_row("New event name", func(n: String) -> void:
		n = n.strip_edges()
		if n.is_empty() or get_event_items().has(n):
			return
		modify("Add Event", func() -> void: _fsm.events = _fsm.events + PackedStringArray([n]))
	))


func _make_add_row(placeholder: String, on_add: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(le)
	var b := Button.new()
	b.text = "Add"
	b.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")
	var go := func() -> void:
		on_add.call(le.text)
		le.text = ""
	b.pressed.connect(go)
	le.text_submitted.connect(func(_t: String) -> void: go.call())
	row.add_child(b)
	return row


func _remove_event(ev: String) -> void:
	var evs := _fsm.events
	var idx := evs.find(ev)
	if idx >= 0:
		evs.remove_at(idx)
		_fsm.events = evs


func _event_usage() -> Dictionary:
	var d := {}
	for st in _fsm.states:
		for t in st.transitions:
			d[t.event] = d.get(t.event, 0) + 1
		for a in st.actions:
			if a == null:
				continue
			for p in _action_properties(a):
				if PropertyRow.is_event_property(p.name):
					var v: String = str(a.get(p.name))
					d[v] = d.get(v, 0) + 1
	for t in _fsm.global_transitions:
		d[t.event] = d.get(t.event, 0) + 1
	return d


func _rename_event(old_name: String, new_name: String) -> void:
	if new_name == old_name or new_name.is_empty():
		return
	if get_event_items().has(new_name):
		push_warning("RunCrafter: event '%s' already exists." % new_name)
		queue_refresh()
		return
	modify("Rename Event", func() -> void:
		var evs := _fsm.events
		var idx := evs.find(old_name)
		if idx >= 0:
			evs[idx] = new_name
			_fsm.events = evs
		for st in _fsm.states:
			for t in st.transitions:
				if t.event == old_name:
					t.event = new_name
			for a in st.actions:
				if a == null:
					continue
				for p in _action_properties(a):
					if PropertyRow.is_event_property(p.name) and str(a.get(p.name)) == old_name:
						a.set(p.name, new_name)
					elif p.type == TYPE_PACKED_STRING_ARRAY and String(p.name).ends_with("events"):
						var arr: PackedStringArray = a.get(p.name)
						for k in arr.size():
							if arr[k] == old_name:
								arr[k] = new_name
						a.set(p.name, arr)
		for t in _fsm.global_transitions:
			if t.event == old_name:
				t.event = new_name
	)
#endregion


#region Variables
## Renames a variable and updates bindings / store_* references in the edited FSM.
func rename_variable(source: Resource, v: RCVariable, new_name: String) -> void:
	var old_ref := v.name
	var new_ref := new_name
	if source is RCGlobals:
		old_ref = "g:" + v.name
		new_ref = "g:" + new_name
		v.name = new_name
		_globals_save_timer.start()
		if _fsm == null:
			queue_refresh()
			return
		modify("Rename Global Variable References", func() -> void: _replace_variable_refs(old_ref, new_ref))
		return
	modify("Rename Variable", func() -> void:
		v.name = new_name
		_replace_variable_refs(old_ref, new_ref)
		if _node and is_instance_valid(_node) and _node.variable_overrides.has(old_ref):
			_node.variable_overrides[new_ref] = _node.variable_overrides[old_ref]
			_node.variable_overrides.erase(old_ref)
	)


func _replace_variable_refs(old_ref: String, new_ref: String) -> void:
	for st in _fsm.states:
		for a in st.actions:
			if a == null:
				continue
			var b := a.bindings.duplicate()
			var changed := false
			for k in b:
				if b[k] == old_ref:
					b[k] = new_ref
					changed = true
			if changed:
				a.bindings = b
			for p in _action_properties(a):
				if PropertyRow.is_variable_property(p.name) and str(a.get(p.name)) == old_ref:
					a.set(p.name, new_ref)
#endregion


#region Globals / FSM panels
func _rebuild_global_events() -> void:
	_clear_children(_global_events_box)
	var et := EditorInterface.get_editor_theme()
	_section(_global_events_box, "Global Events")
	for ev in _globals.events:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = ev
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		l.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
		row.add_child(l)
		row.add_child(_icon_button(et, "Remove", "Delete global event", true, func() -> void:
			var gev := _globals.events
			gev.remove_at(gev.find(ev))
			_globals.events = gev
			_globals_save_timer.start()
			queue_refresh()
		))
		_global_events_box.add_child(row)
	_global_events_box.add_child(_make_add_row("New global event", func(n: String) -> void:
		n = n.strip_edges()
		if n.is_empty() or _globals.events.has(n):
			return
		_globals.events = _globals.events + PackedStringArray([n])
		_globals_save_timer.start()
		queue_refresh()
	))


func _rebuild_fsm_panel() -> void:
	_clear_children(_fsm_box)
	var et := EditorInterface.get_editor_theme()
	var g := GridContainer.new()
	g.columns = 2
	_fsm_box.add_child(g)
	var l1 := Label.new()
	l1.text = "Name"
	g.add_child(l1)
	var name_edit := LineEdit.new()
	name_edit.text = _fsm.fsm_name
	name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	name_edit.text_changed.connect(func(t: String) -> void:
		modify("Rename FSM", func() -> void: _fsm.fsm_name = t, true, false)
	)
	g.add_child(name_edit)
	var l2 := Label.new()
	l2.text = "Start State"
	g.add_child(l2)
	var ob := OptionButton.new()
	var names: Array[String] = []
	for s in _fsm.states:
		names.append(s.state_name)
		ob.add_item(s.state_name, names.size() - 1)
		if s.state_name == _fsm.start_state:
			ob.select(names.size() - 1)
	ob.item_selected.connect(func(i: int) -> void:
		var n := names[i]
		modify("Set Start State", func() -> void: _fsm.start_state = n)
	)
	g.add_child(ob)
	var desc := TextEdit.new()
	desc.placeholder_text = "FSM description…"
	desc.text = _fsm.description
	desc.custom_minimum_size.y = 60 * EditorInterface.get_editor_scale()
	desc.scroll_fit_content_height = true
	desc.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	desc.text_changed.connect(func() -> void:
		var t := desc.text
		modify("Set FSM Description", func() -> void: _fsm.description = t, true, false)
	)
	_fsm_box.add_child(desc)
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.modulate = Color(1, 1, 1, 0.6)
	if _is_file_resource(_fsm):
		info.text = "Shared template: %s\nChanges affect every RCFsmComponent using this file." % _fsm.resource_path
	else:
		info.text = "Embedded in the scene."
	if _node and is_instance_valid(_node):
		var o := get_owner_node()
		info.text += "\nComponent: %s   Owner: %s" % [_node.name, o.name if o else "(not found)"]
	_fsm_box.add_child(info)

	_section(_fsm_box, "Global Transitions (from any state)")
	for i in _fsm.global_transitions.size():
		var t := _fsm.global_transitions[i]
		var row := HBoxContainer.new()
		row.add_child(PropertyRow.make_combo(t.event, get_event_items(), func(s: String) -> void:
			if s == t.event:
				return
			modify("Set Global Transition Event", func() -> void:
				t.event = s
				_ensure_event(s)
			)
		, "(event)"))
		var arrow := Label.new()
		arrow.text = "→"
		row.add_child(arrow)
		var tob := OptionButton.new()
		tob.add_item("(none)", 0)
		for k in names.size():
			tob.add_item(names[k], k + 1)
			if names[k] == t.to_state:
				tob.select(k + 1)
		tob.size_flags_horizontal = SIZE_EXPAND_FILL
		tob.item_selected.connect(func(idx: int) -> void:
			var target := "" if idx == 0 else names[idx - 1]
			modify("Set Global Transition Target", func() -> void: t.to_state = target)
		)
		row.add_child(tob)
		row.add_child(_icon_button(et, "Remove", "Delete global transition", true, func() -> void:
			modify("Delete Global Transition", func() -> void: _fsm.global_transitions.remove_at(i))
		))
		_fsm_box.add_child(row)
	var add := Button.new()
	add.text = "Add Global Transition"
	add.icon = et.get_icon("Add", "EditorIcons")
	add.pressed.connect(func() -> void: _add_global_transition("", _selected_state))
	_fsm_box.add_child(add)
#endregion


#region Templates
func _on_template_menu(id: int) -> void:
	if _fsm == null:
		return
	for c in _file_dialog.file_selected.get_connections():
		_file_dialog.file_selected.disconnect(c.callable)
	match id:
		0:
			_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
			_file_dialog.title = "Save FSM Template"
			_file_dialog.current_file = _fsm.fsm_name.to_snake_case() + ".tres"
			_file_dialog.file_selected.connect(_save_template)
			_file_dialog.popup_file_dialog()
		1:
			if _node == null:
				push_warning("RunCrafter: select a RCFsmComponent node to assign a template.")
				return
			_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
			_file_dialog.title = "Use FSM Template"
			_file_dialog.file_selected.connect(_use_template)
			_file_dialog.popup_file_dialog()
		2:
			if _node == null:
				push_warning("RunCrafter: select a RCFsmComponent node to embed a copy.")
				return
			_assign_fsm(_copy_fsm(_fsm), "Make FSM Unique")


func _copy_fsm(src: RCFsm) -> RCFsm:
	var c := RCFsm.new()
	c.apply_snapshot(src.snapshot())
	return c


func _save_template(path: String) -> void:
	var err := ResourceSaver.save(_copy_fsm(_fsm), path)
	if err != OK:
		push_error("RunCrafter: could not save template (error %d)." % err)
		return
	EditorInterface.get_resource_filesystem().update_file(path)
	print("RunCrafter: template saved to ", path, ". Use Template > Use Template… to link it to other FSM components.")


func _use_template(path: String) -> void:
	var res := ResourceLoader.load(path)
	if not res is RCFsm:
		push_error("RunCrafter: %s is not a RCFsm resource." % path)
		return
	_assign_fsm(res, "Use FSM Template")


func _assign_fsm(f: RCFsm, action_name: String) -> void:
	var ur := plugin.get_undo_redo()
	ur.create_action("RunCrafter: " + action_name, UndoRedo.MERGE_DISABLE, _node)
	ur.add_do_property(_node, "fsm", f)
	ur.add_undo_property(_node, "fsm", _node.fsm)
	ur.commit_action()
	_fsm = f
	queue_refresh()
#endregion


#region Debugging
func on_debug_state(data: Array) -> void:
	if data.size() < 7:
		return
	var res_path: String = data[0]
	var scene_file: String = data[1]
	var rel_path: String = data[2]
	var abs_path: String = data[3]
	var state_name: String = data[4]
	var ev: String = data[5]
	var prev: String = data[6]
	var t := Time.get_time_string_from_system()
	_log.append_text("[color=#888]%s[/color] %s: [color=#aaa]%s[/color] —[color=#fc6]%s[/color]→ [b]%s[/b]\n" % [
		t, abs_path.get_file() if abs_path.get_file() != "" else abs_path, prev if prev != "" else "∅", ev, state_name])
	if _matches_debug(res_path, scene_file, rel_path):
		_debug_state = state_name
		_debug_edge = [prev, ev, state_name]
		_debug_label.text = "● %s" % state_name
		_restyle_graph()


func on_debug_stopped() -> void:
	_debug_state = ""
	_debug_edge = []
	_debug_label.text = ""
	_live_fsms.clear()
	_live_globals = {}
	_update_live_values()
	_restyle_graph()


## Live variable values from a running FSM (see RCFsmComponent._send_debug_vars).
func on_debug_vars(data: Array) -> void:
	if data.size() < 6:
		return
	_live_fsms[data[3]] = [data[0], data[1], data[2], data[4]]
	_live_globals = data[5]
	_update_live_values()


func _update_live_values() -> void:
	var locals := {}
	for k in _live_fsms:
		var e: Array = _live_fsms[k]
		if _matches_debug(e[0], e[1], e[2]):
			locals = e[3]
			break
	_vars_panel.set_live(locals)
	_globals_panel.set_live(_live_globals)


func _matches_debug(res_path: String, scene_file: String, rel_path: String) -> bool:
	if _fsm == null:
		return false
	if not res_path.is_empty() and res_path == _fsm.resource_path:
		return true
	if _node and is_instance_valid(_node) and _node.owner:
		return _node.owner.scene_file_path == scene_file and str(_node.owner.get_path_to(_node)) == rel_path
	return false
#endregion


func _show_help() -> void:
	var d := AcceptDialog.new()
	d.title = "RunCrafter – Quick Help"
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.custom_minimum_size = Vector2(560, 0) * EditorInterface.get_editor_scale()
	l.text = """[b]RunCrafter[/b] – visual finite state machines (PlayMaker-style).

[b]1.[/b] Add a [b]RCFsmComponent[/b] node as a child of the node you want to control and press [i]Create FSM[/i].
[b]2.[/b] Right-click the graph → [i]Add State[/i]. Right-click a state → [i]Add Transition[/i] (pick an event).
[b]3.[/b] Drag an event row (e.g. FINISHED) onto any part of another state to connect it; drop on its own state for a self transition. Empty space or Esc cancels. Right-click an event row for more options.
[b]4.[/b] Select a state and press [i]Add Action…[/i] in the State tab. Actions run top to bottom.
[b]5.[/b] When all actions finish, the state sends [b]FINISHED[/b].
[b]6.[/b] Variables: create them in the Variables tab. The [b]≡[/b] button binds an action parameter to a variable; [i]store_*[/i] fields write results to variables.
[b]7.[/b] Run the game: the active state is highlighted in orange and transitions appear in the Log tab.

From code: [code]$RCFsmComponent.send_event("HIT")[/code], [code]get_var("health")[/code], [code]RCFsmComponent.broadcast(get_tree(), "GAME_OVER")[/code].
Custom actions: extend [code]RCAction[/code] with a [code]class_name[/code] and override [code]_on_enter / _on_update / _on_exit[/code]."""
	d.add_child(l)
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered()
