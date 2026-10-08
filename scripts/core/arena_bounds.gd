extends Node3D
## Procedurally builds a ring of static wall segments around the arena.
## Kept data-driven (radius/height/segments) so later milestones can resize
## or reshape the arena per-phase without hand-placing geometry.

@export var radius: float = 18.0
@export var wall_height: float = 6.0
@export var wall_thickness: float = 1.0
@export var segment_count: int = 24
@export var wall_color: Color = Color(0.45, 0.12, 0.55)

var _material: StandardMaterial3D

func _ready() -> void:
	_build_walls()

## Re-colors every wall segment at once, since they all share one material.
## Used by ArenaEvolution to make the battlefield escalate per phase.
func set_wall_color(color: Color) -> void:
	if _material:
		_material.albedo_color = color
		_material.emission = color

func _build_walls() -> void:
	var segment_length := (TAU * radius / segment_count) * 1.05
	var material := StandardMaterial3D.new()
	material.albedo_color = wall_color
	material.emission_enabled = true
	material.emission = wall_color
	material.emission_energy_multiplier = 0.35
	_material = material

	var box := BoxMesh.new()
	box.size = Vector3(segment_length, wall_height, wall_thickness)

	var shape := BoxShape3D.new()
	shape.size = box.size

	for i in range(segment_count):
		var angle := (TAU / segment_count) * i
		var pos := Vector3(sin(angle), 0.0, cos(angle)) * radius

		var body := StaticBody3D.new()
		body.position = pos
		body.rotation.y = angle
		body.name = "WallSegment%d" % i

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = box
		mesh_instance.material_override = material
		mesh_instance.position.y = wall_height * 0.5
		body.add_child(mesh_instance)

		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position.y = wall_height * 0.5
		body.add_child(collision)

		add_child(body)
