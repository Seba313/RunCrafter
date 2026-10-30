@tool
class_name RCSetShaderParameter
extends RCAction

const CATEGORY := "Rendering"
const DESCRIPTION := "Sets a ShaderMaterial uniform (on a CanvasItem or a MeshInstance3D), or a per-instance uniform."

@export var target: NodePath
@export var parameter: String = ""
## Godot Expression, e.g. "0.5" or "Color(1, 0, 0)"
@export var value_expression: String = ""
## Use set_instance_shader_parameter (GeometryInstance3D, 'instance uniform' in the shader).
@export var instance_uniform: bool = false
## MeshInstance3D surface (-1 = material override).
@export var surface: int = -1
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var n := get_target()
	if n == null:
		return
	var value: Variant = eval(value_expression)
	if instance_uniform and n is GeometryInstance3D:
		n.set_instance_shader_parameter(parameter, value)
		return
	var mat: Material = null
	if n is CanvasItem:
		mat = n.material
	elif n is MeshInstance3D:
		mat = n.material_override if surface < 0 else n.get_active_material(surface)
	elif n is GeometryInstance3D:
		mat = n.material_override
	if mat is ShaderMaterial:
		mat.set_shader_parameter(parameter, value)
	else:
		push_warning("RunCrafter Set Shader Parameter: no ShaderMaterial on %s." % n.name)
