@tool
class_name RCDebugDraw
extends RCAction

const CATEGORY := "Debug"
const DESCRIPTION := "Draws a debug line / sphere (3D) or line / circle (2D) for a while. Positions come from nodes or vectors. Not drawn in release builds (optional)."

@export_enum("Line 3D", "Sphere 3D", "Line 2D", "Circle 2D") var shape: int = 0
## Start / center node (empty = From Position).
@export var from_node: NodePath
@export var from_position: Vector3 = Vector3.ZERO
## End node for lines (empty = To Position).
@export var to_node: NodePath
@export var to_position: Vector3 = Vector3(0, 1, 0)
@export var radius: float = 0.5
@export var color: Color = Color.RED
## Seconds (0 = one frame).
@export var duration: float = 1.0
@export var only_in_debug_builds: bool = true
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	if only_in_debug_builds and not OS.is_debug_build():
		return
	var a: Variant = _pos("from_node", from_position)
	var b: Variant = _pos("to_node", to_position)
	var node: Node
	if shape <= 1:
		var mesh := ImmediateMesh.new()
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.no_depth_test = true
		mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
		if shape == 0:
			mesh.surface_add_vertex(a)
			mesh.surface_add_vertex(b)
		else:
			for axis in 3:
				for i in 32:
					for k in [i, i + 1]:
						var ang: float = TAU * k / 32.0
						var p := Vector3.ZERO
						p[axis] = cos(ang) * radius
						p[(axis + 1) % 3] = sin(ang) * radius
						mesh.surface_add_vertex(a + p)
		mesh.surface_end()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node = mi
	else:
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = color
		var a2 := Vector2(a.x, a.y)
		if shape == 2:
			line.points = PackedVector2Array([a2, Vector2(b.x, b.y)])
		else:
			var pts := PackedVector2Array()
			for i in 33:
				pts.append(a2 + Vector2.from_angle(TAU * i / 32.0) * radius)
			line.points = pts
		node = line
	var parent := fsm.get_tree().current_scene if fsm.get_tree().current_scene else fsm.get_tree().root
	parent.add_child(node)
	if duration <= 0.0:
		fsm.get_tree().process_frame.connect(node.queue_free, CONNECT_ONE_SHOT)
	else:
		fsm.get_tree().create_timer(duration, false).timeout.connect(node.queue_free)


func _pos(prop: String, fallback: Vector3) -> Variant:
	var n := get_optional_target(prop)
	if n is Node3D:
		return n.global_position
	if n is Node2D:
		var p: Vector2 = n.global_position
		return Vector3(p.x, p.y, 0)
	return fallback
