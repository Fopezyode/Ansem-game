class_name HealthPickup
extends Area3D
## A glowing pickup that heals on touch. Detects the player via its Hurtbox
## (layer 4) rather than the combat Hitbox system, since this isn't damage.
## Expires on its own if left uncollected, so drops never pile up on screen.

@export var heal_amount: float = 20.0
@export var lifetime: float = 12.0
@export var fade_time: float = 1.0

@onready var visual: Node3D = $Visual

var _collected: bool = false
var _fading: bool = false
var _life_timer: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_life_timer = lifetime

func _process(delta: float) -> void:
	visual.rotation.y += 2.0 * delta
	if _collected or _fading:
		return
	_life_timer -= delta
	if _life_timer <= 0.0:
		_expire()

func _on_area_entered(area: Area3D) -> void:
	if _collected or _fading or not (area is Hurtbox):
		return
	var hurtbox := area as Hurtbox
	if hurtbox.health_component == null:
		return
	_collected = true
	# Area3D forbids changing monitoring from inside its own area_entered
	# callback (the physics step is still iterating overlaps) — must defer.
	set_deferred("monitoring", false)
	hurtbox.health_component.heal(heal_amount)

	var tween := create_tween()
	tween.tween_property(visual, "scale", visual.scale * 1.6, 0.15)
	tween.parallel().tween_property(self, "position:y", position.y + 1.2, 0.4)
	tween.tween_callback(queue_free)

func _expire() -> void:
	_fading = true
	monitoring = false
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3.ZERO, fade_time)
	tween.tween_callback(queue_free)
