@tool
class_name RCSetEnvironmentProperty
extends RCAction

const CATEGORY := "Rendering"
const DESCRIPTION := "Sets a property of the WorldEnvironment's Environment (fog_density, glow_intensity, tonemap_exposure...), optionally over time."

## WorldEnvironment (empty = first one found in the current scene).
@export var target: NodePath
@export var property: String = "fog_density"
@export var value_expression: String = ""
@export var duration: float = 0.0
@export var finish_event: String = ""


func _on_enter() -> void:
	var env := _environment()
	if env == null:
		push_warning("RunCrafter Set Environment Property: no WorldEnvironment found.")
		finish()
		return
	var value: Variant = eval(value_expression)
	if duration <= 0.0 or not (value is float or value is int or value is Color):
		env.set(property, value)
		_done()
		return
	var t := fsm.create_tween()
	t.tween_property(env, property, value, duration)
	t.finished.connect(_done)


func _environment() -> Environment:
	var n := get_optional_target("target")
	if n == null:
		var found := fsm.get_tree().current_scene.find_children("*", "WorldEnvironment", true, false)
		n = found[0] if not found.is_empty() else null
	return n.environment if n is WorldEnvironment else null


func _done() -> void:
	finish()
	send_event(finish_event)
