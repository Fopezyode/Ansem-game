class_name TrumpWallsAttack
extends BossAttack
## Raises temporary barrier walls near the player, forcing a reroute. Solid
## until the player has the Control Core, which lets Bull Charge shatter them.

const WallScene := preload("res://scenes/core/breakable_wall.tscn")

@export var wall_count: int = 2
@export var distance_from_player: float = 5.0
@export var wall_lifetime: float = 5.0

func execute(boss: Node) -> void:
	var player: Node = boss.get_player()
	var player_pos: Vector3 = player.global_position
	for i in range(wall_count):
		var angle: float = randf() * TAU
		var pos: Vector3 = player_pos + Vector3(sin(angle), 0.0, cos(angle)) * distance_from_player
		pos.y = 0.0
		var wall: BreakableWall = WallScene.instantiate()
		boss.get_tree().current_scene.add_child(wall)
		wall.global_position = pos
		wall.rotation.y = angle + PI * 0.5
		wall.player = player
		wall.lifetime = wall_lifetime
	await get_tree().create_timer(wall_lifetime + 0.6).timeout
