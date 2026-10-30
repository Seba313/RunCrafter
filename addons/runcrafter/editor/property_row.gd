@tool
extends HBoxContainer
## One editable property (label + value editor + optional variable binding button).
## Used for action properties and for variable values.

const BIND_COLOR := Color(0.55, 0.85, 1.0)

## The FSM editor (provides variables, events, owner node...).
var ctx: Object
var target: Object
var info: Dictionary
## func(property: String, value: Variant)
var on_change: Callable
## func(property: String, variable_name: String) - invalid Callable = no binding support.
var on_bind: Callable
var binding: String = ""
var show_label: bool = true

var _bind_choices: Array = []

const NEW_VARIABLE_ID := 100000


func setup(p_ctx: Object, p_target: Object, p_info: Dictionary, p_on_change: Callable,
		p_on_bind: Callable = Callable(), p_binding: String = "", p_show_label: bool = true) -> void:
	ctx = p_ctx
	target = p_target
	info = p_info
	on_change = p_on_change
	on_bind = p_on_bind
	binding = p_binding
	show_label = p_show_label
	size_flags_horizontal = SIZE_EXPAND_FILL
	_build()


#region Property name conventions
static func is_variable_property(prop: String) -> bool:
	return prop.begins_with("store_") or prop == "variable" or prop.ends_with("_variable")


static func is_event_property(prop: String) -> bool:
	return prop == "event" or prop.ends_with("_event")


static func is_signal_property(prop: String) -> bool:
	return prop == "signal_name" or prop.ends_with("_signal_name")


static func is_input_action_property(prop: String) -> bool:
	return prop.ends_with("input_action")


static func is_compatible(prop_type: int, var_type: int) -> bool:
	if prop_type == var_type:
		return true
	var num := [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]
	if prop_type in num and var_type in num:
		return true
	if prop_type == TYPE_NODE_PATH and var_type in [TYPE_OBJECT, TYPE_STRING]:
		return true
	if prop_type in [TYPE_STRING, TYPE_STRING_NAME]:
		return true
	return false
#endregion


## Maps a property type to the closest supported variable type.
static func to_variable_type(t: int) -> int:
	match t:
		TYPE_NODE_PATH:
			return TYPE_OBJECT
		TYPE_STRING_NAME:
			return TYPE_STRING
		TYPE_PACKED_STRING_ARRAY:
			return TYPE_ARRAY
	return t if t in RCVariable.TYPES else TYPE_FLOAT


## Best guess of the type of a variable created for a store_* / variable property.
static func guess_variable_type(target: Object, prop: String) -> int:
	var title := ""
	if target is RCAction:
		title = (target as RCAction).get_title().to_lower()
	# "Set X Value" style actions: same type as their value.
	if (prop == "variable" or prop.ends_with("_variable")) and target and "value" in target:
		return to_variable_type(typeof(target.get("value")))
	var n := prop.trim_prefix("store_")
	if n in ["x", "y", "z", "length", "speed", "time", "delta", "state_time"]:
		return TYPE_FLOAT
	if n in ["state_name", "previous_state", "last_event"]:
		return TYPE_STRING
	if n.contains("vector2"):
		return TYPE_VECTOR2
	if n.contains("vector3"):
		return TYPE_VECTOR3
	if n.contains("node") or n == "other":
		return TYPE_OBJECT
	if n == "all_arguments":
		return TYPE_ARRAY
	if n in ["vector", "hit_point", "hit_normal"]:
		return TYPE_VECTOR2 if title.contains("2d") else TYPE_VECTOR3
	# Checks/tests first ("Int Compare" stores a bool, not an int).
	var by_title := [["compare", TYPE_BOOL], ["test", TYPE_BOOL], ["is ", TYPE_BOOL], ["contains", TYPE_BOOL],
			["valid", TYPE_BOOL], ["bool", TYPE_BOOL], ["array", TYPE_ARRAY], ["vector3", TYPE_VECTOR3],
			["vector2", TYPE_VECTOR2], ["mouse", TYPE_VECTOR2], ["float", TYPE_FLOAT], ["distance", TYPE_FLOAT],
			["axis", TYPE_FLOAT], ["int", TYPE_INT], ["count", TYPE_INT], ["string", TYPE_STRING],
			["text", TYPE_STRING], ["find", TYPE_OBJECT], ["instantiate", TYPE_OBJECT]]
	for pair in by_title:
		if title.contains(pair[0]):
			return pair[1]
	return TYPE_FLOAT


func _build() -> void:
	var prop: String = info.name
	if show_label:
		var l := Label.new()
		l.text = prop.capitalize()
		l.custom_minimum_size.x = 130 * EditorInterface.get_editor_scale()
		l.clip_text = true
		l.tooltip_text = prop
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(l)
	if not binding.is_empty():
		var bl := Label.new()
		bl.text = "⇢ " + binding
		bl.tooltip_text = "Value read from variable '%s'." % binding
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
		bl.size_flags_horizontal = SIZE_EXPAND_FILL
		bl.add_theme_color_override("font_color", BIND_COLOR)
		add_child(bl)
	else:
		var ed := _make_editor()
		ed.size_flags_horizontal = SIZE_EXPAND_FILL
		add_child(ed)
	if on_bind.is_valid() and _is_bindable():
		add_child(_make_bind_button())


func _is_bindable() -> bool:
	var prop: String = info.name
	if is_variable_property(prop) or is_event_property(prop):
		return false
	return info.type in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2,
			TYPE_VECTOR3, TYPE_COLOR, TYPE_NODE_PATH, TYPE_OBJECT, TYPE_ARRAY, TYPE_DICTIONARY]


func _make_bind_button() -> MenuButton:
	var mb := MenuButton.new()
	mb.text = "≡"
	mb.flat = false
	mb.tooltip_text = "Use a variable instead of a fixed value"
	if not binding.is_empty():
		mb.add_theme_color_override("font_color", BIND_COLOR)
	var pm := mb.get_popup()
	_bind_choices.clear()
	pm.add_item("Use fixed value", 0)
	pm.add_separator()
	var vars: Array = ctx.get_variable_infos()
	for v in vars:
		if is_compatible(info.type, v.type):
			_bind_choices.append(v.name)
			pm.add_item(v.label, _bind_choices.size())
	if not _bind_choices.is_empty():
		pm.add_separator()
	pm.add_item("New Variable…", NEW_VARIABLE_ID)
	pm.id_pressed.connect(func(id: int) -> void:
		if id == 0:
			on_bind.call(info.name, "")
		elif id == NEW_VARIABLE_ID:
			ctx.prompt_new_variable(info.name, to_variable_type(info.type), func(n: String) -> void:
				on_bind.call(info.name, n)
			)
		elif id <= _bind_choices.size():
			on_bind.call(info.name, _bind_choices[id - 1])
	)
	return mb


func _commit(v: Variant) -> void:
	on_change.call(info.name, v)


func _make_editor() -> Control:
	var prop: String = info.name
	var t: int = info.type
	var hint: int = info.get("hint", PROPERTY_HINT_NONE)
	var hs: String = info.get("hint_string", "")
	var val: Variant = target.get(prop)
	match t:
		TYPE_BOOL:
			var cb := CheckBox.new()
			cb.button_pressed = bool(val)
			cb.text = "On"
			cb.toggled.connect(func(p: bool) -> void: _commit(p))
			return cb
		TYPE_INT:
			if hint == PROPERTY_HINT_ENUM:
				return _make_enum_int(int(val), hs)
			var s := _spin(float(val), true)
			s.value_changed.connect(func(f: float) -> void: _commit(int(f)))
			return s
		TYPE_FLOAT:
			var s := _spin(float(val), false)
			s.value_changed.connect(func(f: float) -> void: _commit(f))
			return s
		TYPE_STRING, TYPE_STRING_NAME:
			return _make_string_editor(str(val) if val != null else "", hint, hs)
		TYPE_VECTOR2:
			return _make_vector(val if val is Vector2 else Vector2.ZERO, 2)
		TYPE_VECTOR3:
			return _make_vector(val if val is Vector3 else Vector3.ZERO, 3)
		TYPE_COLOR:
			var cp := ColorPickerButton.new()
			cp.color = val if val is Color else Color.WHITE
			cp.custom_minimum_size = Vector2(60, 24) * EditorInterface.get_editor_scale()
			cp.color_changed.connect(func(c: Color) -> void: _commit(c))
			return cp
		TYPE_NODE_PATH:
			return _make_node_path(val if val is NodePath else NodePath())
		TYPE_OBJECT:
			var rp := EditorResourcePicker.new()
			rp.base_type = hs if hint == PROPERTY_HINT_RESOURCE_TYPE and not hs.is_empty() else "Resource"
			rp.edited_resource = val if val is Resource else null
			rp.resource_changed.connect(func(r: Resource) -> void: _commit(r))
			return rp
		TYPE_PACKED_STRING_ARRAY:
			var te := TextEdit.new()
			te.text = "\n".join(val if val is PackedStringArray else PackedStringArray())
			te.placeholder_text = "One entry per line"
			te.custom_minimum_size.y = 64 * EditorInterface.get_editor_scale()
			te.scroll_fit_content_height = true
			te.text_changed.connect(func() -> void:
				var lines := PackedStringArray()
				for line in te.text.split("\n"):
					if not line.strip_edges().is_empty():
						lines.append(line.strip_edges())
				_commit(lines)
			)
			return te
	# Fallback: edit as text (var_to_str / str_to_var).
	var le := LineEdit.new()
	le.text = var_to_str(val) if val != null else ""
	le.tooltip_text = "Godot value syntax, e.g. [1, 2, 3] or {\"a\": 1}"
	var apply := func() -> void:
		var parsed: Variant = str_to_var(le.text)
		if parsed != null and typeof(parsed) == t:
			_commit(parsed)
	le.text_submitted.connect(func(_s: String) -> void: apply.call())
	le.focus_exited.connect(apply)
	return le


func _spin(v: float, is_int: bool) -> SpinBox:
	var s := SpinBox.new()
	s.allow_greater = true
	s.allow_lesser = true
	s.min_value = -1e9
	s.max_value = 1e9
	s.step = 1.0 if is_int else 0.001
	if info.get("hint", 0) == PROPERTY_HINT_RANGE:
		var parts: PackedStringArray = str(info.get("hint_string", "")).split(",")
		if parts.size() >= 2:
			s.min_value = parts[0].to_float()
			s.max_value = parts[1].to_float()
			s.allow_greater = parts.has("or_greater")
			s.allow_lesser = parts.has("or_less")
		if parts.size() >= 3 and parts[2].is_valid_float():
			s.step = parts[2].to_float()
	s.value = v
	s.select_all_on_focus = true
	s.custom_minimum_size.x = 70 * EditorInterface.get_editor_scale()
	return s


func _make_enum_int(v: int, hs: String) -> OptionButton:
	var ob := OptionButton.new()
	var next := 0
	for item in hs.split(","):
		var label := item
		var value := next
		if item.contains(":"):
			label = item.get_slice(":", 0)
			value = item.get_slice(":", 1).to_int()
		ob.add_item(label.strip_edges(), value)
		next = value + 1
	var idx := ob.get_item_index(v)
	if idx >= 0:
		ob.select(idx)
	ob.fit_to_longest_item = false
	ob.clip_text = true
	ob.item_selected.connect(func(i: int) -> void: _commit(ob.get_item_id(i)))
	return ob


func _make_string_editor(v: String, hint: int, hs: String) -> Control:
	var prop: String = info.name
	if is_variable_property(prop):
		var names := PackedStringArray()
		for vi in ctx.get_variable_infos():
			names.append(vi.name)
		var c := make_combo(v, names, func(s: String) -> void: _commit(s), "(none)", "New Variable…",
				func(line: LineEdit) -> void:
					ctx.prompt_new_variable(prop.trim_prefix("store_"), guess_variable_type(target, prop), func(n: String) -> void:
						line.text = n
						_commit(n)
					)
		)
		c.tooltip_text = "Variable to write the result to"
		var le: LineEdit = c.get_child(0)
		if not v.is_empty() and not names.has(v):
			le.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
			le.tooltip_text = "Variable '%s' does not exist." % v
		return c
	if is_event_property(prop):
		return make_combo(v, ctx.get_event_items(), func(s: String) -> void: _commit(s), "(no event)")
	if is_signal_property(prop):
		var info_list: Array = ctx.get_signal_items(target, prop)
		var names := PackedStringArray()
		var labels := PackedStringArray()
		for si in info_list:
			names.append(si.name)
			labels.append(si.label)
		var c := make_combo(v, names, func(s: String) -> void: _commit(s), "(signal)", "", Callable(), labels)
		var le: LineEdit = c.get_child(0)
		if names.is_empty():
			le.tooltip_text = "Pick the target node to get a list of its signals."
		elif not v.is_empty() and not names.has(v):
			le.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
			le.tooltip_text = "The target node has no signal '%s'." % v
		else:
			var idx := names.find(v)
			le.tooltip_text = labels[idx] if idx >= 0 else ""
		return c
	if is_input_action_property(prop):
		return make_combo(v, ctx.get_input_actions(), func(s: String) -> void: _commit(s), "(input action)")
	if hint == PROPERTY_HINT_ENUM:
		var ob := OptionButton.new()
		var items := hs.split(",")
		for i in items.size():
			ob.add_item(items[i], i)
			if items[i] == v:
				ob.select(i)
		ob.item_selected.connect(func(i: int) -> void: _commit(items[i]))
		return ob
	if hint == PROPERTY_HINT_MULTILINE_TEXT:
		var te := TextEdit.new()
		te.text = v
		te.custom_minimum_size.y = 56 * EditorInterface.get_editor_scale()
		te.scroll_fit_content_height = true
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		te.text_changed.connect(func() -> void: _commit(te.text))
		return te
	var le := LineEdit.new()
	le.text = v
	le.text_changed.connect(func(s: String) -> void: _commit(s))
	if hint in [PROPERTY_HINT_FILE, PROPERTY_HINT_GLOBAL_FILE]:
		var box := HBoxContainer.new()
		le.size_flags_horizontal = SIZE_EXPAND_FILL
		box.add_child(le)
		var b := Button.new()
		b.text = "…"
		b.tooltip_text = "Browse"
		b.pressed.connect(func() -> void:
			var fd := EditorFileDialog.new()
			fd.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
			fd.access = EditorFileDialog.ACCESS_RESOURCES
			for f in hs.split(",", false):
				fd.add_filter(f.strip_edges())
			fd.file_selected.connect(func(path: String) -> void:
				le.text = path
				_commit(path)
				fd.queue_free()
			)
			fd.canceled.connect(fd.queue_free)
			EditorInterface.get_base_control().add_child(fd)
			fd.popup_file_dialog()
		)
		box.add_child(b)
		return box
	return le


func _make_vector(v: Variant, n: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	var spins: Array[SpinBox] = []
	var axes := ["x", "y", "z"]
	for i in n:
		var l := Label.new()
		l.text = axes[i]
		l.modulate = [Color(1, 0.5, 0.5), Color(0.6, 1, 0.6), Color(0.6, 0.7, 1)][i]
		box.add_child(l)
		var s := _spin(v[i], false)
		s.custom_minimum_size.x = 56 * EditorInterface.get_editor_scale()
		s.size_flags_horizontal = SIZE_EXPAND_FILL
		box.add_child(s)
		spins.append(s)
	for s in spins:
		s.value_changed.connect(func(_f: float) -> void:
			if n == 2:
				_commit(Vector2(spins[0].value, spins[1].value))
			else:
				_commit(Vector3(spins[0].value, spins[1].value, spins[2].value))
		)
	return box


func _make_node_path(v: NodePath) -> HBoxContainer:
	var box := HBoxContainer.new()
	var le := LineEdit.new()
	le.text = str(v)
	le.placeholder_text = "(owner)"
	le.size_flags_horizontal = SIZE_EXPAND_FILL
	le.tooltip_text = "Path relative to the FSM owner node. Empty = the owner itself."
	le.text_submitted.connect(func(s: String) -> void: _commit(NodePath(s)))
	le.focus_exited.connect(func() -> void: _commit(NodePath(le.text)))
	box.add_child(le)
	var b := Button.new()
	b.text = "⊙"
	b.tooltip_text = "Pick a node from the scene"
	var owner_node: Node = ctx.get_owner_node()
	b.disabled = owner_node == null
	b.pressed.connect(func() -> void:
		EditorInterface.popup_node_selector(func(p: NodePath) -> void:
			if p.is_empty():
				return
			var root := EditorInterface.get_edited_scene_root()
			var o: Node = ctx.get_owner_node()
			if root == null or o == null:
				return
			# Works for paths relative to the scene root and for absolute paths.
			var picked := root.get_node_or_null(p)
			if picked == null:
				return
			var rel := o.get_path_to(picked)
			if picked == o:
				rel = NodePath()
			le.text = str(rel)
			_commit(rel)
		)
	)
	box.add_child(b)
	return box


## LineEdit + drop-down list of suggestions. [param on_commit] receives the text.
## Optional [param extra_label] adds a last menu item that calls [param on_extra] with the LineEdit.
## Optional [param labels] (same size as items) are shown in the menu instead of the values.
static func make_combo(text: String, items: PackedStringArray, on_commit: Callable, placeholder: String = "",
		extra_label: String = "", on_extra: Callable = Callable(), labels: PackedStringArray = PackedStringArray()) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	var le := LineEdit.new()
	le.text = text
	le.placeholder_text = placeholder
	le.size_flags_horizontal = SIZE_EXPAND_FILL
	le.custom_minimum_size.x = 80 * EditorInterface.get_editor_scale()
	var mb := MenuButton.new()
	mb.text = "▾"
	mb.flat = false
	var pm := mb.get_popup()
	pm.add_item("(none)", 0)
	for i in items.size():
		pm.add_item(labels[i] if labels.size() == items.size() else items[i], i + 1)
	if not extra_label.is_empty() and on_extra.is_valid():
		pm.add_separator()
		pm.add_item(extra_label, NEW_VARIABLE_ID)
	pm.id_pressed.connect(func(id: int) -> void:
		if id == NEW_VARIABLE_ID:
			on_extra.call(le)
			return
		var s := "" if id == 0 else items[id - 1]
		le.text = s
		on_commit.call(s)
	)
	le.text_submitted.connect(func(s: String) -> void: on_commit.call(s.strip_edges()))
	le.focus_exited.connect(func() -> void: on_commit.call(le.text.strip_edges()))
	box.add_child(le)
	box.add_child(mb)
	return box
