class_name HealthComponent
extends Node
## Reusable health/damage authority. Attach to any damageable entity
## (player, champion, boss, training dummy) and drive it through a Hurtbox.

signal health_changed(current: float, max: float)
signal damaged(amount: float)
signal died

@export var max_health: float = 100.0

var current_health: float
var invulnerable: bool = false

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	if invulnerable or is_dead():
		return
	current_health = max(current_health - amount, 0.0)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	if is_dead():
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func revive() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0.0
