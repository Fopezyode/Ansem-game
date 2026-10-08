class_name Hurtbox
extends Area3D
## Passive damage receiver. Owns the rules for whether a hit lands, is
## dodged (invulnerable), or is parried, then forwards to HealthComponent.

enum HitResult { IGNORED, DAMAGED, PARRIED }

@export var health_component: HealthComponent

signal parried_attack(hitbox: Hitbox)

var is_parrying: bool = false

func _ready() -> void:
	monitoring = false
	monitorable = true

func receive_hit(hitbox: Hitbox) -> HitResult:
	if health_component == null or health_component.is_dead():
		return HitResult.IGNORED
	if health_component.invulnerable:
		return HitResult.IGNORED
	if is_parrying and hitbox.can_be_parried:
		parried_attack.emit(hitbox)
		return HitResult.PARRIED
	health_component.take_damage(hitbox.damage)
	return HitResult.DAMAGED
