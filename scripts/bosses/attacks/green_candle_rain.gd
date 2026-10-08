class_name GreenCandleRainAttack
extends BossAttack
## Waves of smaller, faster ground hazards scattered across a wide area
## around the player. Many and quick, in contrast to Market Crash's few
## heavy-hitting ones — forces continuous repositioning rather than one dodge.

const HazardScene := preload("res://scenes/core/ground_hazard.tscn")

@export var wave_count: int = 2
@export var hazards_per_wave: int = 6
@export var spawn_radius: float = 10.0
@export var stagger_time: float = 0.15
@export var wave_gap_time: float = 0.6
@export var telegraph_time: float = 0.7
@export var active_time: float = 0.3
@export var damage: float = 10.0

func execute(boss: Node) -> void:
	for wave in range(wave_count):
		for i in range(hazards_per_wave):
			_spawn_hazard(boss)
			await get_tree().create_timer(stagger_time).timeout
		if wave < wave_count - 1:
			await get_tree().create_timer(wave_gap_time).timeout

func _spawn_hazard(boss: Node) -> void:
	var hazard: GroundHazard = HazardScene.instantiate()
	boss.get_tree().current_scene.add_child(hazard)
	hazard.damage = damage
	hazard.windup_time = telegraph_time
	hazard.active_time = active_time
	var angle: float = randf() * TAU
	var dist: float = sqrt(randf()) * spawn_radius
	var pos: Vector3 = boss.get_player().global_position + Vector3(sin(angle), 0.0, cos(angle)) * dist
	pos.y = 0.0
	hazard.detonate_at(pos)
