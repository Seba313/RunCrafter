@tool
extends VBoxContainer
## Editor for a list of RCVariable (FSM variables or global variables).

const PropertyRow := preload("res://addons/runcrafter/editor/property_row.gd")

var ctx: Object
## RCFsm or RCGlobals (both have a "variables" array).
var source: Resource
var is_global: bool = false


func rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if source == null:
		return
	var s := EditorInterface.get_editor_scale()
	var help := Label.new()
	help.text = "Global variables are shared by all FSMs (saved in %s)." % RCGlobals.globals_path() if is_global \
			else "Local variables of this FSM. Check \"Inspector\" to expose a variable for per-instance overrides."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.modulate = Color(1, 1, 1, 0.6)
	add_child(help)
	for v in source.variables:
		if v == null:
			continue
		add_child(_make_variable_panel(v, s))
	# Add row
	var add := HBoxContainer.new()
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "New variable name"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add.add_child(name_edit)
	var type_btn := _make_type_button(TYPE_FLOAT)
	add.add_child(type_btn)
	var add_btn := Button.new()
	add_btn.text = "Add"
	add_btn.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")
	var do_add := func() -> void:
		var n := name_edit.text.strip_edges().replace(" ", "_")
		if n.is_empty():
			n = source.unique_variable_name("global" if is_global else "variable")
		if not n.is_valid_identifier():
			push_warning("RunCrafter: variable names must be valid identifiers (letters, digits, _).")
			return
		if source.get_variable(n) != null:
			push_warning("RunCrafter: variable '%s' already exists." % n)
			return
		var t := type_btn.get_selected_id()
		ctx.modify_variables(source, "Add Variable", func() -> void:
			var nv := RCVariable.new()
			nv.name = n
			nv.type = t
			source.variables.append(nv)
		)
	add_btn.pressed.connect(do_add)
	name_edit.text_submitted.connect(func(_t: String) -> void: do_add.call())
	add.add_child(add_btn)
	add_child(add)


func _make_variable_panel(v: RCVariable, s: float) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(4 * s)
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var line := HBoxContainer.new()
	vb.add_child(line)
	var name_edit := LineEdit.new()
	name_edit.text = v.name
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rename := func() -> void:
		var n := name_edit.text.strip_edges().replace(" ", "_")
		if n == v.name:
			return
		if n.is_empty() or not n.is_valid_identifier() or source.get_variable(n) != null:
			push_warning("RunCrafter: invalid or duplicate variable name '%s'." % n)
			name_edit.text = v.name
			return
		ctx.rename_variable(source, v, n)
	name_edit.text_submitted.connect(func(_t: String) -> void: rename.call())
	name_edit.focus_exited.connect(rename)
	line.add_child(name_edit)
	var type_btn := _make_type_button(v.type)
	type_btn.item_selected.connect(func(i: int) -> void:
		var t := type_btn.get_item_id(i)
		ctx.modify_variables(source, "Change Variable Type", func() -> void: v.type = t)
	)
	line.add_child(type_btn)
	if not is_global:
		var ex := CheckBox.new()
		ex.text = "Inspector"
		ex.tooltip_text = "Expose in the Inspector of the RCFsmComponent (per-instance value)."
		ex.button_pressed = v.exposed
		ex.toggled.connect(func(p: bool) -> void:
			ctx.modify_variables(source, "Expose Variable", func() -> void: v.exposed = p)
		)
		line.add_child(ex)
	var del := Button.new()
	del.icon = EditorInterface.get_editor_theme().get_icon("Remove", "EditorIcons")
	del.tooltip_text = "Delete variable"
	del.flat = true
	del.pressed.connect(func() -> void:
		ctx.modify_variables(source, "Delete Variable", func() -> void: source.variables.erase(v))
	)
	line.add_child(del)
	var row := PropertyRow.new()
	var pinfo := {"name": "value", "type": v.type}
	if v.type == TYPE_OBJECT:
		pinfo["hint"] = PROPERTY_HINT_RESOURCE_TYPE
		pinfo["hint_string"] = "Resource"
	row.setup(ctx, v, pinfo, func(_p: String, val: Variant) -> void:
		ctx.modify_variables(source, "Set Variable Value", func() -> void: v.value = val, true, false)
	, Callable(), "", false)
	if v.type == TYPE_OBJECT:
		row.tooltip_text = "Object variables usually hold nodes assigned at runtime (Find Node, Instantiate, Trigger Event...)."
	vb.add_child(row)
	return panel


func _make_type_button(selected: int) -> OptionButton:
	var ob := OptionButton.new()
	for t in RCVariable.TYPES:
		ob.add_item(RCVariable.type_label(t), t)
	ob.select(ob.get_item_index(selected))
	return ob
