class_name PumpShockburstAttack
extends BossAttack
## A radial burst of shots from Pump's own position — pressure at range too,
## so kiting far away doesn't trivialize the fight.

const ProjectileScene := preload("res://scenes/core/telegraphed_projectile.tscn")

@export var shot_count: int = 8
@export var telegraph_time: float = 0.9
@export var travel_speed: float = 8.0
@export var damage: float = 10.0

func execute(boss: Node) -> void:
	var origin: Vector3 = boss.global_position + Vector3(0, 1.2, 0)
	for i in range(shot_count):
		var angle: float = (TAU / shot_count) * i
		var dir := Vector3(sin(angle), 0.0, cos(angle))
		var shot: TelegraphedProjectile = ProjectileScene.instantiate()
		boss.get_tree().current_scene.add_child(shot)
		shot.windup_time = telegraph_time
		shot.travel_speed = travel_speed
		shot.damage = damage
		shot.launch(origin, dir)
	await get_tree().create_timer(telegraph_time + 1.0).timeout
