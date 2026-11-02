@tool
extends EditorPlugin
## RunCrafter editor plugin: adds the "RunCrafter" main screen (visual FSM editor)
## and a debugger plugin for live state highlighting.

const FsmEditor := preload("res://addons/runcrafter/editor/fsm_editor.gd")
const DebuggerPlugin := preload("res://addons/runcrafter/editor/debugger_plugin.gd")
const InspectorPlugin := preload("res://addons/runcrafter/editor/inspector_plugin.gd")
const ICON := preload("res://addons/runcrafter/icons/fsm.svg")

var _editor: FsmEditor
var _debugger: DebuggerPlugin
var _inspector: InspectorPlugin


func _enter_tree() -> void:
	if not ProjectSettings.has_setting(RCGlobals.SETTING):
		ProjectSettings.set_setting(RCGlobals.SETTING, RCGlobals.DEFAULT_PATH)
	ProjectSettings.set_initial_value(RCGlobals.SETTING, RCGlobals.DEFAULT_PATH)
	ProjectSettings.add_property_info({"name": RCGlobals.SETTING, "type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE, "hint_string": "*.tres"})
	_editor = FsmEditor.new()
	_editor.plugin = self
	_editor.name = "RunCrafter"
	EditorInterface.get_editor_main_screen().add_child(_editor)
	_editor.hide()
	_debugger = DebuggerPlugin.new()
	_debugger.editor = _editor
	add_debugger_plugin(_debugger)
	scene_changed.connect(_on_scene_changed)
	_inspector = InspectorPlugin.new()
	_inspector.plugin = self
	add_inspector_plugin(_inspector)
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)


func _exit_tree() -> void:
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	var sel := EditorInterface.get_selection()
	if sel.selection_changed.is_connected(_on_selection_changed):
		sel.selection_changed.disconnect(_on_selection_changed)
	if _inspector:
		remove_inspector_plugin(_inspector)
		_inspector = null
	if _debugger:
		remove_debugger_plugin(_debugger)
		_debugger = null
	if _editor:
		_editor.queue_free()
		_editor = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _editor:
		_editor.visible = visible


func _get_plugin_name() -> String:
	return "RunCrafter"


func _get_plugin_icon() -> Texture2D:
	return ICON


func _handles(object: Object) -> bool:
	return object is RCFsmComponent or object is RCFsm


func _edit(object: Object) -> void:
	if _editor and object:
		_editor.edit_object(object)


func _save_external_data() -> void:
	if _editor:
		_editor.save_external()


func _on_scene_changed(root: Node) -> void:
	if _editor == null:
		return
	var n := _editor.get_edited_node()
	if n and (root == null or (n != root and not root.is_ancestor_of(n))):
		_editor.clear_edit()


## Opens an FSM component in the RunCrafter main screen.
func open_fsm(fsm_node: RCFsmComponent) -> void:
	if _editor == null or not is_instance_valid(fsm_node):
		return
	_editor.edit_object(fsm_node)
	EditorInterface.set_main_screen_editor("RunCrafter")


## Selecting the node that OWNS an FSM (like a GameObject in PlayMaker) loads its FSM
## into the RunCrafter editor without switching the main screen away from 2D/3D.
## Selecting a node without an FSM shows an empty screen with an "Add FSM" button.
func _on_selection_changed() -> void:
	if _editor == null:
		return
	var nodes := EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() != 1:
		return
	# Godot does not always call _edit() for the FSM node itself (e.g. while another
	# FSM is open), so load it here as well.
	if nodes[0] is RCFsmComponent:
		if nodes[0] != _editor.get_edited_node():
			_editor.edit_object(nodes[0])
		return
	var fsms := InspectorPlugin.find_fsms(nodes[0])
	if fsms.is_empty():
		_editor.show_no_fsm(nodes[0])
	elif fsms[0] != _editor.get_edited_node():
		_editor.edit_object(fsms[0])
