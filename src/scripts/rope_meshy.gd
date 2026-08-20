extends Node
class_name RopeMesh

@export_group("Rope Mesh")
@export var rope_radius: float = 0.03
@export var rope_color: Color = Color(0.35, 0.25, 0.15)
@export var rope_start_offset: Vector3 = Vector3(0, 0, 0.0)
@export var rope_tex: Texture

var rope_mesh_instance: MeshInstance3D
var rope_cylinder: CylinderMesh

## setupping prob not required, but nice to have in memory, although it is a single 4 sided mesh :P
func _ready() -> void:
	_setup_rope_visual()

func _setup_rope_visual() -> void:
	rope_cylinder = CylinderMesh.new()
	rope_cylinder.top_radius = rope_radius
	rope_cylinder.bottom_radius = rope_radius
	rope_cylinder.height = 1.0
	rope_cylinder.radial_segments = 6

	var mat := StandardMaterial3D.new()
	#mat.albedo_color = rope_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.albedo_texture = rope_tex

	mat.texture_repeat = BaseMaterial3D.FLAG_USE_TEXTURE_REPEAT
	mat.uv1_scale = Vector3(1.0, 10.0, 1.0)
	rope_cylinder.material = mat

	rope_mesh_instance = MeshInstance3D.new()
	rope_mesh_instance.mesh = rope_cylinder
	rope_mesh_instance.visible = false
	rope_mesh_instance.top_level = true
	add_child(rope_mesh_instance)

func _update_rope_visual(is_swinging: bool, from: Vector3, to: Vector3) -> void:
	if rope_mesh_instance == null:
		return

	rope_mesh_instance.visible = is_swinging
	if not is_swinging:
		return

	var start := from + rope_start_offset
	var to_anchor := to - start
	var distance := to_anchor.length()
	if distance < 0.001:
		rope_mesh_instance.visible = false
		return

	rope_cylinder.height = distance
	rope_mesh_instance.global_position = start + to_anchor * 0.5
	rope_mesh_instance.global_transform.basis = calc_rope_dir(to_anchor / distance)


func calc_rope_dir(up: Vector3) -> Basis:
	var reference := Vector3.RIGHT
	if abs(up.dot(reference)) > 0.99:
		reference = Vector3.FORWARD
	var x_axis := reference.cross(up).normalized()
	var z_axis := up.cross(x_axis).normalized()
	return Basis(x_axis, up, z_axis)
