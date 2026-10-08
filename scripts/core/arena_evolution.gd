extends Node
## Reacts to overall game phase changes (GameProgression) by evolving the
## arena's look: walls shift toward hotter/angrier colors and ambient
## lighting intensifies each phase, so the battlefield visibly escalates as
## champions fall — the "Arena Evolves" step of the game loop.

@export var wall_bounds_path: NodePath
@export var environment_path: NodePath

const PHASE_WALL_COLORS := [
	Color(0.45, 0.12, 0.55),
	Color(0.6, 0.15, 0.5),
	Color(0.75, 0.15, 0.35),
	Color(0.9, 0.2, 0.2),
	Color(1.0, 0.65, 0.15),
]
const PHASE_AMBIENT_ENERGY := [0.6, 0.8, 1.0, 1.3, 1.6]

@onready var wall_bounds: Node = get_node(wall_bounds_path)
@onready var world_environment: WorldEnvironment = get_node(environment_path)

func _ready() -> void:
	GameProgression.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase_index: int, _label: String) -> void:
	var idx: int = clamp(phase_index, 0, PHASE_WALL_COLORS.size() - 1)
	if wall_bounds.has_method("set_wall_color"):
		wall_bounds.set_wall_color(PHASE_WALL_COLORS[idx])

	var env: Environment = world_environment.environment
	var tween := create_tween()
	tween.tween_property(env, "ambient_light_energy", PHASE_AMBIENT_ENERGY[idx], 1.5)
