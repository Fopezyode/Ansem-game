class_name PepeFakeCollectibleAttack
extends BossAttack
## Pepe drops fake glowing "collectibles" nearby — bait for a greedy player.
## Telegraphed exactly like every other hazard (grows/brightens before it's
## live), so chasing shinies is a fair risk, not a cheap trick.

const FakeCollectibleScene := preload("res://scenes/bosses/attacks/fake_collectible.tscn")

@export var spawn_count: int = 2
@export var spawn_radius_min: float = 3.0
@export var spawn_radius_max: float = 7.0
@export var windup_time: float = 1.6
@export var active_time: float = 1.0
@export var damage: float = 15.0

func execute(boss: Node) -> void:
	var player_pos: Vector3 = boss.get_player().global_position
	for i in range(spawn_count):
		var fake: GroundHazard = FakeCollectibleScene.instantiate()
		boss.get_tree().current_scene.add_child(fake)
		fake.windup_time = windup_time
		fake.active_time = active_time
		fake.damage = damage
		var angle: float = randf() * TAU
		var dist: float = randf_range(spawn_radius_min, spawn_radius_max)
		var pos: Vector3 = player_pos + Vector3(sin(angle), 0.0, cos(angle)) * dist
		pos.y = 0.8
		fake.detonate_at(pos)
	await get_tree().create_timer(windup_time + active_time).timeout
