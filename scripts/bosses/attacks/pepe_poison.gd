class_name PepePoisonAttack
extends BossAttack
## Spawns lingering toxic pools around the player that tick damage while
## stood in, rather than a single hit — punishes staying still, not just
## bad positioning.

const PoisonScene := preload("res://scenes/core/poison_zone.tscn")

@export var pool_count: int = 2
@export var spawn_radius: float = 7.0
@export var windup_time: float = 1.0
@export var duration: float = 4.0
@export var tick_interval: float = 1.0
@export var damage_per_tick: float = 6.0

func execute(boss: Node) -> void:
	var player_pos: Vector3 = boss.get_player().global_position
	for i in range(pool_count):
		var pool: PoisonZone = PoisonScene.instantiate()
		boss.get_tree().current_scene.add_child(pool)
		pool.windup_time = windup_time
		pool.duration = duration
		pool.tick_interval = tick_interval
		pool.damage_per_tick = damage_per_tick
		var angle: float = (TAU / pool_count) * i + randf_range(-0.4, 0.4)
		var dist: float = randf_range(2.5, spawn_radius)
		var pos: Vector3 = player_pos + Vector3(sin(angle), 0.0, cos(angle)) * dist
		pos.y = 0.0
		pool.detonate_at(pos)
	await get_tree().create_timer(windup_time + 0.5).timeout
