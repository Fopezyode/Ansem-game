class_name WifWindGustAttack
extends BossAttack
## A wind gust that hits where the player was standing (telegraphed, so
## moving away avoids the damage) and knocks them back — disruption first,
## damage second.

const ProjectileScene := preload("res://scenes/core/telegraphed_projectile.tscn")

@export var telegraph_time: float = 0.9
@export var push_strength: float = 9.0
@export var damage: float = 5.0

func execute(boss: Node) -> void:
	var player: Node = boss.get_player()

	var gust: TelegraphedProjectile = ProjectileScene.instantiate()
	boss.get_tree().current_scene.add_child(gust)
	gust.windup_time = telegraph_time
	gust.travel_speed = 0.0
	gust.lifetime = telegraph_time + 0.4
	gust.damage = damage
	gust.launch(player.global_position + Vector3(0, 1.0, 0), Vector3.FORWARD)

	await get_tree().create_timer(telegraph_time).timeout

	var dir: Vector3 = player.global_position - boss.global_position
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	if "apply_impulse" in player:
		player.apply_impulse(dir, push_strength)

	await get_tree().create_timer(0.4).timeout
