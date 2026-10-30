@tool
class_name RCLoadVariables
extends RCAction

const CATEGORY := "Scene"
const DESCRIPTION := "Loads variables saved with Save Variables."

## Variable names (g:name for globals). Empty = all local variables of this FSM.
@export var variables: PackedStringArray = PackedStringArray()
@export var file_name: String = "savegame.cfg"
@export var section: String = "game"
@export var success_event: String = ""
## Sent when the file (or section) does not exist yet.
@export var missing_event: String = ""


func _on_enter() -> void:
	finish()
	var cfg := ConfigFile.new()
	if cfg.load(_path()) != OK or not cfg.has_section(section):
		send_event(missing_event)
		return
	for n in _names():
		if cfg.has_section_key(section, n):
			set_var(n, cfg.get_value(section, n))
	send_event(success_event)


func _names() -> PackedStringArray:
	if not variables.is_empty():
		return variables
	var out := PackedStringArray()
	for v in fsm.runtime.variables:
		out.append(v.name)
	return out


func _path() -> String:
	return file_name if file_name.contains("://") else "user://" + file_name
