@tool
class_name RCSetLight
extends RCAction

const CATEGORY := "Rendering"
const DESCRIPTION := "Sets the energy and color of a Light2D/Light3D, optionally over time."

@export var target: NodePath
@export var energy: float = 1.0
@export var set_color: bool = false
@export var color: Color = Color.WHITE
@export var duration: float = 0.0
@export var finish_event: String = ""

var _tween: Tween


func _on_enter() -> void:
	var l := get_target()
	if not (l is Light3D or l is Light2D):
		finish()
		return
	var energy_prop := "light_energy" if l is Light3D else "energy"
	var color_prop := "light_color" if l is Light3D else "color"
	if duration <= 0.0:
		l.set(energy_prop, energy)
		if set_color:
			l.set(color_prop, color)
		_done()
		return
	_tween = l.create_tween().set_parallel()
	_tween.tween_property(l, energy_prop, energy, duration)
	if set_color:
		_tween.tween_property(l, color_prop, color, duration)
	_tween.finished.connect(_done)


func _done() -> void:
	_tween = null
	finish()
	send_event(finish_event)
