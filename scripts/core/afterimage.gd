class_name Afterimage
extends Node3D
## Attached at runtime to a duplicated visual (e.g. the bull's mesh) to turn
## it into a fading translucent ghost. Used by the Chaos Core's dash trail.

@export var fade_time: float = 0.3
@export var color: Color = Color(0.3, 0.9, 1.0, 0.5)

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	_apply_material_recursive(self, mat)

	var tween := create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, fade_time)
	tween.tween_callback(queue_free)

func _apply_material_recursive(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)
