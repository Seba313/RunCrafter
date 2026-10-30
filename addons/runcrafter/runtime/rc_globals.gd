@tool
@icon("res://addons/runcrafter/icons/fsm_resource.svg")
class_name RCGlobals
extends Resource
## Global variables and global events shared by all FSMs (like PlayMaker Globals).
## Stored in the file set in Project Settings > runcrafter/globals_path.

const SETTING := "runcrafter/globals_path"
const DEFAULT_PATH := "res://runcrafter_globals.tres"

@export var variables: Array[RCVariable] = []
@export var events: PackedStringArray = PackedStringArray()

const META := &"runcrafter_globals"

var _var_map: Dictionary = {}


static func globals_path() -> String:
	return str(ProjectSettings.get_setting(SETTING, DEFAULT_PATH))


## Runtime instance (a private copy so the asset on disk is never modified while playing).
## Stored as metadata of the SceneTree root, so it lives as long as the game.
static func get_runtime() -> RCGlobals:
	var tree := Engine.get_main_loop() as SceneTree
	var holder: Object = tree.root if tree else Engine.get_main_loop()
	if holder and holder.has_meta(META):
		return holder.get_meta(META)
	var rt := RCGlobals.new()
	var path := globals_path()
	if ResourceLoader.exists(path):
		var src := load(path) as RCGlobals
		if src:
			rt.events = src.events.duplicate()
			for v in src.variables:
				if v == null:
					continue
				var nv := RCFsm.clone_resource(v) as RCVariable
				nv.value = v.get_value_copy()
				rt.variables.append(nv)
	for v in rt.variables:
		rt._var_map[v.name] = v
	if holder:
		holder.set_meta(META, rt)
	return rt


## Editor helper: loads (or creates) the globals asset.
static func load_for_editor() -> RCGlobals:
	var path := globals_path()
	if ResourceLoader.exists(path):
		var g := load(path) as RCGlobals
		if g:
			return g
	var ng := RCGlobals.new()
	ng.resource_path = path
	return ng


func get_variable(n: String) -> RCVariable:
	if not _var_map.is_empty():
		return _var_map.get(n)
	for v in variables:
		if v.name == n:
			return v
	return null


func unique_variable_name(base: String = "global") -> String:
	var n := base
	var i := 1
	while get_variable(n) != null:
		i += 1
		n = "%s%d" % [base, i]
	return n
