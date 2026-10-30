@tool
class_name RCSaveVariables
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Saves FSM / global variables to a file in user:// (ConfigFile). Object variables are skipped."

## Variable names (g:name for globals). Empty = all local variables of this FSM.
@export var variables: PackedStringArray = PackedStringArray()
@export var file_name: String = "savegame.cfg"
@export var section: String = "game"
@export var success_event: String = ""
@export var failed_event: String = ""


func _on_enter() -> void:
	finish()
	var cfg := ConfigFile.new()
	cfg.load(_path())
	for n in _names():
		var v: Variant = get_var(n)
		if v is Object:
			continue
		cfg.set_value(section, n, v)
	var err := cfg.save(_path())
	send_event(success_event if err == OK else failed_event)


func _names() -> PackedStringArray:
	if not variables.is_empty():
		return variables
	var out := PackedStringArray()
	for v in fsm.runtime.variables:
		out.append(v.name)
	return out


func _path() -> String:
	return file_name if file_name.contains("://") else "user://" + file_name
