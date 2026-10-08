class_name WifTornadoesAttack
extends BossAttack
## Spawns tornadoes near the player that pull them toward the core and
## tick damage if dragged in. Countering one (Parry timed near the core)
## sends it flying back at Wif.

const TornadoScene := preload("res://scenes/core/tornado.tscn")

@export var tornado_count: int = 1
@export var spawn_radius: float = 6.0
@export var lifetime: float = 5.0

func execute(boss: Node) -> void:
	var player: Node = boss.get_player()
	var player_pos: Vector3 = player.global_position
	for i in range(tornado_count):
		var angle: float = randf() * TAU
		var dist: float = randf_range(3.0, spawn_radius)
		var pos: Vector3 = player_pos + Vector3(sin(angle), 0.0, cos(angle)) * dist
		pos.y = 0.0
		var tornado: Tornado = TornadoScene.instantiate()
		boss.get_tree().current_scene.add_child(tornado)
		tornado.player = player
		tornado.boss = boss
		tornado.lifetime = lifetime
		tornado.detonate_at(pos)
	await get_tree().create_timer(lifetime + 1.0).timeout
