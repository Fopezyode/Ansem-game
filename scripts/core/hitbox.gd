class_name Hitbox
extends Area3D
## Active damage source. Attached to attacks (bull charge, ultimate, boss
## projectiles). Scans for Hurtbox areas on its collision_mask and resolves
## the hit through them, so all damage rules live in one place (Hurtbox).

signal landed_hit(hurtbox: Hurtbox)
signal parried

@export var damage: float = 10.0
@export var can_be_parried: bool = true
@export var one_shot: bool = true
## Identifies which specific ability this hitbox belongs to, for systems
## that care (e.g. BreakableWall only shatters to a tagged "bull_charge" hit).
@export var tag: String = ""

var _already_hit: Array[Hurtbox] = []

func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)

func reset_hits() -> void:
	_already_hit.clear()

func _on_area_entered(area: Area3D) -> void:
	if not (area is Hurtbox):
		return
	var hurtbox := area as Hurtbox
	if one_shot and hurtbox in _already_hit:
		return
	var result := hurtbox.receive_hit(self)
	match result:
		Hurtbox.HitResult.PARRIED:
			parried.emit()
		Hurtbox.HitResult.DAMAGED:
			_already_hit.append(hurtbox)
			landed_hit.emit(hurtbox)
