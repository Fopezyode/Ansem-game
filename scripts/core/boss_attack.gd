class_name BossAttack
extends Node
## Base class for every boss/champion attack. Each concrete attack is its own
## scene instanced under the boss's "Attacks" container, so adding a new
## attack later never means touching the boss's own script.

@export var weight: float = 1.0

## Override in subclasses. Must fully resolve (await internally as needed)
## before returning — the boss stays in ATTACKING state until this completes.
func execute(_boss: Node) -> void:
	pass

## Optional: override to actually cut the attack short when the boss lands
## a charge-interrupt punish (see BossBase.try_interrupt). Attacks that
## directly move the boss's own body (dashes/lunges) or hold an ongoing
## hitbox (beams) should force their completion signal early here. Attacks
## that only spawn independent hazards can skip this — the hazards finish
## on their own regardless.
func interrupt() -> void:
	pass
