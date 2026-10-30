@tool
@icon("res://addons/runcrafter/icons/fsm_resource.svg")
class_name RCVariable
extends Resource
## A typed, named variable owned by an FSM (or by the global variables asset).
##
## Actions can read variables through property bindings and write them through
## "store_*" / "variable" properties.

## Variant types supported by FSM variables (in the order shown in editors).
const TYPES: Array[int] = [TYPE_FLOAT, TYPE_INT, TYPE_BOOL, TYPE_STRING, TYPE_VECTOR2,
		TYPE_VECTOR3, TYPE_COLOR, TYPE_OBJECT, TYPE_ARRAY, TYPE_DICTIONARY]

@export var name: String = ""
@export_enum("Float:3", "Int:2", "Bool:1", "String:4", "Vector2:5", "Vector3:9", "Color:20",
		"Object:24", "Array:28", "Dictionary:27") var type: int = TYPE_FLOAT:
	set(v):
		if type == v:
			return
		type = v
		if not is_compatible(value, v):
			if typeof(value) in [TYPE_INT, TYPE_FLOAT] and v in [TYPE_INT, TYPE_FLOAT]:
				value = type_convert(value, v)
			else:
				value = default_value(v)
		notify_property_list_changed()
## Show this variable in the Inspector of every RCFsmComponent using the FSM,
## so it can be overridden per instance.
@export var exposed: bool = false
@export_multiline var tooltip: String = ""

var value: Variant = 0.0


func _get_property_list() -> Array[Dictionary]:
	var p := {"name": "value", "type": type, "usage": PROPERTY_USAGE_DEFAULT}
	if type == TYPE_OBJECT:
		p["hint"] = PROPERTY_HINT_RESOURCE_TYPE
		p["hint_string"] = "Resource"
	return [p]


func _property_can_revert(property: StringName) -> bool:
	return property == &"value"


func _property_get_revert(property: StringName) -> Variant:
	if property == &"value":
		return default_value(type)
	return null


static func default_value(t: int) -> Variant:
	match t:
		TYPE_BOOL: return false
		TYPE_INT: return 0
		TYPE_FLOAT: return 0.0
		TYPE_STRING: return ""
		TYPE_VECTOR2: return Vector2.ZERO
		TYPE_VECTOR3: return Vector3.ZERO
		TYPE_COLOR: return Color.WHITE
		TYPE_ARRAY: return []
		TYPE_DICTIONARY: return {}
	return null


static func is_compatible(v: Variant, t: int) -> bool:
	if t == TYPE_OBJECT:
		return v == null or v is Object
	return typeof(v) == t


static func type_label(t: int) -> String:
	return "Object" if t == TYPE_OBJECT else type_string(t)


## Copy of the current value that does not share containers with this variable.
func get_value_copy() -> Variant:
	if value is Array or value is Dictionary:
		return value.duplicate(true)
	return value
