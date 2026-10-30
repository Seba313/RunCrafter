@tool
class_name RCSetShaderGlobal
extends RCAction

const CATEGORY := "Rendering"
const DESCRIPTION := "Sets a global shader parameter (Project Settings > Shader Globals)."

@export var parameter: String = ""
@export var value_expression: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	RenderingServer.global_shader_parameter_set(StringName(parameter), eval(value_expression))
