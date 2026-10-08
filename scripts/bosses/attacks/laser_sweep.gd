class_name LaserSweepAttack
extends BossAttack
## Telegraphs a beam aimed at the player's position, then sweeps it across a
## fixed arc. Readable and dodgeable: the beam glows brighter through the
## telegraph, then the sweep is slow enough to walk out of if you react.

signal finished

@export var telegraph_time: float = 1.2
@export var sweep_duration: float = 1.0
@export var sweep_arc_degrees: float = 55.0
@export var damage: float = 20.0

@onready var pivot: Node3D = $Pivot
@onready var beam_mesh: MeshInstance3D = $Pivot/BeamMesh
@onready var hitbox: Hitbox = $Pivot/BeamMesh/Hitbox
@onready var beam_mat: StandardMaterial3D = beam_mesh.get_surface_override_material(0)

enum Phase { INACTIVE, TELEGRAPH, SWEEP }
var _phase: Phase = Phase.INACTIVE
var _timer: float = 0.0
var _start_angle: float = 0.0
var _end_angle: float = 0.0

func _ready() -> void:
	# This attack lives permanently under the boss (unlike the spawned-per-use
	# hazards), so its Hitbox must start disabled explicitly — Hitbox's own
	# _ready() defaults monitoring to true.
	hitbox.monitoring = false
	beam_mesh.visible = false

func execute(boss: Node) -> void:
	var to_player: Vector3 = boss.get_player().global_position - pivot.global_position
	to_player.y = 0.0
	var base_angle := atan2(to_player.x, to_player.z)
	_start_angle = base_angle - deg_to_rad(sweep_arc_degrees) * 0.5
	_end_angle = base_angle + deg_to_rad(sweep_arc_degrees) * 0.5

	pivot.global_rotation.y = _start_angle
	hitbox.damage = damage
	hitbox.monitoring = false
	hitbox.reset_hits()
	beam_mesh.visible = true

	_phase = Phase.TELEGRAPH
	_timer = telegraph_time
	await finished

func interrupt() -> void:
	if _phase == Phase.INACTIVE:
		return
	_phase = Phase.INACTIVE
	hitbox.monitoring = false
	beam_mesh.visible = false
	finished.emit()

func _physics_process(delta: float) -> void:
	match _phase:
		Phase.TELEGRAPH:
			_timer -= delta
			var t: float = 1.0 - clamp(_timer / telegraph_time, 0.0, 1.0)
			beam_mat.emission_energy_multiplier = lerp(0.3, 2.5, t)
			if _timer <= 0.0:
				_phase = Phase.SWEEP
				_timer = sweep_duration
				hitbox.monitoring = true
		Phase.SWEEP:
			_timer -= delta
			var t: float = clamp(1.0 - _timer / sweep_duration, 0.0, 1.0)
			pivot.global_rotation.y = lerp_angle(_start_angle, _end_angle, t)
			if _timer <= 0.0:
				_phase = Phase.INACTIVE
				hitbox.monitoring = false
				beam_mesh.visible = false
				finished.emit()
