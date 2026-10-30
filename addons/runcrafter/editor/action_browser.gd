@tool
extends AcceptDialog
## Searchable, categorized list of all RCAction classes (built-in and user-made).

signal action_chosen(script: Script)

var _search: LineEdit
var _tree: Tree
var _desc: RichTextLabel
var _entries: Array[Dictionary] = []


func _init() -> void:
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title = "Add Action"
	ok_button_text = "Add Action"
	var vb := VBoxContainer.new()
	add_child(vb)
	_search = LineEdit.new()
	_search.placeholder_text = "Search actions…"
	_search.clear_button_enabled = true
	_search.text_changed.connect(func(_t: String) -> void: _fill())
	_search.text_submitted.connect(func(_t: String) -> void: _choose())
	_search.gui_input.connect(_on_search_input)
	vb.add_child(_search)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(split)
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.custom_minimum_size.x = 300
	_tree.item_selected.connect(_on_selected)
	_tree.item_activated.connect(_choose)
	split.add_child(_tree)
	_desc = RichTextLabel.new()
	_desc.bbcode_enabled = true
	_desc.custom_minimum_size.x = 240
	_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_desc)
	confirmed.connect(_choose)


func popup_browser() -> void:
	_scan()
	_search.text = ""
	_fill()
	var s := EditorInterface.get_editor_scale()
	popup_centered(Vector2i(int(760 * s), int(520 * s)))
	_search.grab_focus.call_deferred()


func _scan() -> void:
	_entries.clear()
	var classes := ProjectSettings.get_global_class_list()
	var base_of := {}
	for c in classes:
		base_of[String(c["class"])] = String(c["base"])
	for c in classes:
		var cn := String(c["class"])
		if cn == "RCAction":
			continue
		var b: String = base_of.get(cn, "")
		var guard := 0
		while not b.is_empty() and b != "RCAction" and guard < 32:
			b = base_of.get(b, "")
			guard += 1
		if b != "RCAction":
			continue
		var script := load(String(c["path"])) as Script
		if script == null:
			continue
		_entries.append({
			"script": script,
			"class": cn,
			"title": RCAction.title_for_script(script),
			"category": RCAction.category_for_script(script),
			"description": RCAction.description_for_script(script),
			"path": String(c["path"]),
		})
	_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.category != b.category:
			return a.category < b.category
		return a.title < b.title
	)


func _fill() -> void:
	_tree.clear()
	var root := _tree.create_item()
	var filter := _search.text.strip_edges().to_lower()
	var cats := {}
	var first: TreeItem = null
	for e in _entries:
		if not filter.is_empty():
			var hay := ("%s %s %s %s" % [e.title, e.category, e.description, e["class"]]).to_lower()
			if not hay.contains(filter):
				continue
		if not cats.has(e.category):
			var ci := _tree.create_item(root)
			ci.set_text(0, e.category)
			ci.set_selectable(0, false)
			ci.set_custom_color(0, Color(0.7, 0.85, 1.0))
			ci.collapsed = filter.is_empty()
			cats[e.category] = ci
		var it := _tree.create_item(cats[e.category])
		it.set_text(0, e.title)
		it.set_tooltip_text(0, e.description)
		it.set_metadata(0, e)
		if first == null:
			first = it
	if first and not filter.is_empty():
		first.select(0)
		_tree.scroll_to_item(first)
	_desc.text = "[i]%d actions. Double-click to add.[/i]" % _entries.size() if filter.is_empty() else ""


func _on_selected() -> void:
	var it := _tree.get_selected()
	if it == null or it.get_metadata(0) == null:
		return
	var e: Dictionary = it.get_metadata(0)
	_desc.text = "[b]%s[/b]\n[color=#8ab]%s[/color]\n\n%s\n\n[color=#888]%s\n%s[/color]" % [
		e.title, e.category, e.description, e["class"], e.path]


func _on_search_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode in [KEY_DOWN, KEY_UP]:
		_tree.grab_focus()
		_search.accept_event()


func _choose() -> void:
	var it := _tree.get_selected()
	if it == null or it.get_metadata(0) == null:
		return
	var e: Dictionary = it.get_metadata(0)
	hide()
	action_chosen.emit(e.script)
