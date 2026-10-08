class_name TrumpHazardFieldAttack
extends BossAttack
## Scatters hazards across the whole arena rather than clustering them near
## the player — Trump doesn't just threaten you, he constrains the whole
## battlefield ("Arena Control").

const HazardScene := preload("res://scenes/core/ground_hazard.tscn")

@export var hazard_count: int = 5
@export var arena_radius: float = 15.0
@export var telegraph_time: float = 1.3
@export var active_time: float = 0.4
@export var damage: float = 15.0

func execute(boss: Node) -> void:
	for i in range(hazard_count):
		var angle: float = randf() * TAU
		var dist: float = sqrt(randf()) * arena_radius
		var pos := Vector3(sin(angle) * dist, 0.0, cos(angle) * dist)
		var hazard: GroundHazard = HazardScene.instantiate()
		boss.get_tree().current_scene.add_child(hazard)
		hazard.windup_time = telegraph_time
		hazard.active_time = active_time
		hazard.damage = damage
		hazard.detonate_at(pos)
	await get_tree().create_timer(telegraph_time + active_time).timeout
