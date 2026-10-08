class_name TrumpGroundSlamAttack
extends BossAttack
## Trump slams the ground, sending a ripple of shockwave hazards outward
## from him toward the player. Pure reuse of GroundHazard, just orchestrated
## as a directional line instead of a cluster.

const HazardScene := preload("res://scenes/core/ground_hazard.tscn")

@export var ring_count: int = 3
@export var ring_spacing: float = 3.5
@export var stagger_time: float = 0.25
@export var telegraph_time: float = 0.9
@export var active_time: float = 0.35
@export var damage: float = 20.0

func execute(boss: Node) -> void:
	var boss_pos: Vector3 = boss.global_position
	var player_pos: Vector3 = boss.get_player().global_position
	var dir: Vector3 = player_pos - boss_pos
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD

	for i in range(ring_count):
		_spawn_ring(boss, boss_pos + dir * ring_spacing * (i + 1))
		await get_tree().create_timer(stagger_time).timeout
	await get_tree().create_timer(telegraph_time + active_time).timeout

func _spawn_ring(boss: Node, pos: Vector3) -> void:
	var hazard: GroundHazard = HazardScene.instantiate()
	boss.get_tree().current_scene.add_child(hazard)
	hazard.windup_time = telegraph_time
	hazard.active_time = active_time
	hazard.damage = damage
	pos.y = 0.0
	hazard.detonate_at(pos)
