extends Node3D
## Periodically spawns a HealthPickup at a random point in the arena, on a
## randomized interval, so long fights aren't an unbroken war of attrition.
## Pickup size scales with its heal amount: small = little, big = a lot.

const PickupScene := preload("res://scenes/core/health_pickup.tscn")

const TIERS: Array[Dictionary] = [
	{"heal": 10.0, "scale": 0.7, "weight": 0.6},
	{"heal": 20.0, "scale": 1.0, "weight": 0.3},
	{"heal": 35.0, "scale": 1.4, "weight": 0.1},
]

@export var min_interval: float = 15.0
@export var max_interval: float = 20.0
@export var spawn_radius: float = 14.0

var _timer: float = 0.0

func _ready() -> void:
	_reset_timer()

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_spawn_pickup()
		_reset_timer()

func _reset_timer() -> void:
	_timer = randf_range(min_interval, max_interval)

func _spawn_pickup() -> void:
	var pickup: HealthPickup = PickupScene.instantiate()
	get_tree().current_scene.add_child(pickup)

	var tier := _choose_tier()
	pickup.heal_amount = tier["heal"]
	pickup.scale = Vector3.ONE * float(tier["scale"])

	var angle: float = randf() * TAU
	var dist: float = sqrt(randf()) * spawn_radius
	pickup.global_position = Vector3(sin(angle) * dist, 1.0, cos(angle) * dist)

func _choose_tier() -> Dictionary:
	var total := 0.0
	for t in TIERS:
		total += t["weight"]
	var roll := randf() * total
	for t in TIERS:
		roll -= t["weight"]
		if roll <= 0.0:
			return t
	return TIERS[-1]
