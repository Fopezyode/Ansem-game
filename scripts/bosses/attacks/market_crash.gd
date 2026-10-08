class_name MarketCrashAttack
extends BossAttack
## A handful of large, slow-telegraphed ground hazards spread around the
## player. Few and heavy-hitting, in contrast to Green Candle Rain's many
## small scattered ones.

const HazardScene := preload("res://scenes/core/ground_hazard.tscn")

@export var hazard_count: int = 3
@export var spawn_radius: float = 6.0
@export var telegraph_time: float = 1.4
@export var active_time: float = 0.5
@export var damage: float = 25.0

func execute(boss: Node) -> void:
	var player_pos: Vector3 = boss.get_player().global_position
	for i in range(hazard_count):
		var hazard: GroundHazard = HazardScene.instantiate()
		boss.get_tree().current_scene.add_child(hazard)
		hazard.damage = damage
		hazard.windup_time = telegraph_time
		hazard.active_time = active_time
		var angle: float = (TAU / hazard_count) * i + randf_range(-0.3, 0.3)
		var dist: float = randf_range(2.0, spawn_radius)
		var pos: Vector3 = player_pos + Vector3(sin(angle), 0.0, cos(angle)) * dist
		pos.y = 0.0
		hazard.detonate_at(pos)
	await get_tree().create_timer(telegraph_time + active_time).timeout
