@tool
class_name RCSampleNoise
extends RCAction

const CATEGORY := "Math"
const DESCRIPTION := "Samples a Noise resource (e.g. FastNoiseLite) at a 1D/2D/3D position. Result is -1..1."

@export var noise: Noise
@export var position: Vector3 = Vector3.ZERO
@export_enum("1D (x)", "2D (x y)", "3D") var dimensions: int = 1
## Adds the time since the game started to X (animated noise).
@export var scroll_with_time: float = 0.0
@export var store_result: String = ""
@export var every_frame: bool = true


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	if noise == null:
		return
	var p := position + Vector3(Time.get_ticks_msec() / 1000.0 * scroll_with_time, 0, 0)
	var v := 0.0
	match dimensions:
		0: v = noise.get_noise_1d(p.x)
		1: v = noise.get_noise_2d(p.x, p.y)
		2: v = noise.get_noise_3d(p.x, p.y, p.z)
	store(store_result, v)
