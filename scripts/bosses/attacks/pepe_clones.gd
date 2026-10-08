class_name PepeClonesAttack
extends BossAttack
## Pepe splits into illusory clones that flank the player and each fire one
## telegraphed shot, then fade away.

const ProjectileScene := preload("res://scenes/core/telegraphed_projectile.tscn")

@export var clone_count: int = 2
@export var clone_radius: float = 8.0
@export var clone_lifetime: float = 2.0
@export var damage: float = 12.0

func execute(boss: Node) -> void:
	var boss_pos: Vector3 = boss.global_position
	var player_pos: Vector3 = boss.get_player().global_position
	for i in range(clone_count):
		var angle: float = (TAU / clone_count) * i + randf_range(-0.3, 0.3)
		var pos: Vector3 = boss_pos + Vector3(sin(angle), 0.0, cos(angle)) * clone_radius
		pos.y = boss_pos.y
		_spawn_clone(boss, pos, player_pos)
	await get_tree().create_timer(clone_lifetime).timeout

func _spawn_clone(boss: Node, pos: Vector3, player_pos: Vector3) -> void:
	var clone: Node3D = boss.get_visual_clone()
	boss.get_tree().current_scene.add_child(clone)
	clone.global_position = pos
	var to_player: Vector3 = player_pos - pos
	clone.rotation.y = atan2(to_player.x, to_player.z)

	var projectile: TelegraphedProjectile = ProjectileScene.instantiate()
	boss.get_tree().current_scene.add_child(projectile)
	projectile.damage = damage
	var aim: Vector3 = (player_pos + Vector3(0, 1.0, 0)) - (pos + Vector3(0, 1.5, 0))
	projectile.launch(pos + Vector3(0, 1.5, 0), aim)

	var tween := clone.create_tween()
	tween.tween_interval(max(clone_lifetime - 0.4, 0.1))
	tween.tween_property(clone, "scale", Vector3.ZERO, 0.4)
	tween.tween_callback(clone.queue_free)
