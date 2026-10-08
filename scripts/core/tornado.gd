class_name Tornado
extends Node3D
## A hazard that pulls the player toward its center via decaying impulses,
## and deals tick damage if they're dragged into its inner core. Reused by
## Wif's Tornadoes attack. Time a Parry while caught near the core and it
## gets countered — flung back at whichever boss spawned it.

@export var pull_radius: float = 5.0
@export var pull_strength: float = 4.4
@export var damage_radius: float = 1.5
@export var damage_per_tick: float = 8.0
@export var tick_interval: float = 0.5
@export var lifetime: float = 5.0
@export var windup_time: float = 1.0
@export var spin_speed: float = 6.0
@export var counter_radius: float = 2.5
@export var counter_damage: float = 40.0
@export var counter_travel_time: float = 0.35

@onready var visual: Node3D = $Visual
@onready var hitbox: Hitbox = $Hitbox

var player: Node = null
var boss: Node = null

var _windup_timer: float = 0.0
var _life_timer: float = 0.0
var _tick_timer: float = 0.0
var _active: bool = false
var _countered: bool = false

func detonate_at(pos: Vector3) -> void:
	global_position = pos
	_windup_timer = windup_time
	_life_timer = lifetime
	_tick_timer = 0.0
	_active = false
	_countered = false
	visual.scale = Vector3.ONE * 0.2
	hitbox.damage = damage_per_tick
	hitbox.monitoring = false

func _physics_process(delta: float) -> void:
	if _countered:
		return

	visual.rotation.y += spin_speed * delta

	if not _active:
		_windup_timer -= delta
		var t: float = 1.0 - clamp(_windup_timer / windup_time, 0.0, 1.0)
		visual.scale = Vector3.ONE * lerp(0.2, 1.0, t)
		if _windup_timer <= 0.0:
			_active = true
			hitbox.monitoring = true
		return

	if _check_counter():
		return

	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return

	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_pull_player()

## Polled every physics frame (not just on the damage tick) so the narrow
## parry window can't be missed between ticks.
func _check_counter() -> bool:
	if player == null:
		return false
	var hurtbox: Hurtbox = player.get_node("Hurtbox")
	if not hurtbox.is_parrying:
		return false
	var dist: float = (global_position - player.global_position).length()
	if dist > counter_radius:
		return false
	_trigger_counter(hurtbox)
	return true

func _trigger_counter(hurtbox: Hurtbox) -> void:
	_countered = true
	_active = false
	hitbox.monitoring = false
	hurtbox.parried_attack.emit(hitbox)

	if boss == null or not is_instance_valid(boss):
		queue_free()
		return

	var boss_health: HealthComponent = boss.get_node("Health")
	var tween := create_tween()
	tween.tween_property(self, "global_position", boss.global_position, counter_travel_time)
	tween.parallel().tween_property(visual, "scale", Vector3.ZERO, counter_travel_time)
	tween.tween_callback(func():
		if is_instance_valid(boss_health) and not boss_health.is_dead():
			boss_health.take_damage(counter_damage)
		queue_free()
	)

func _pull_player() -> void:
	if player == null:
		return
	var to_center: Vector3 = global_position - player.global_position
	to_center.y = 0.0
	var dist: float = to_center.length()
	if dist > pull_radius or dist < 0.01:
		return

	if "apply_impulse" in player:
		player.apply_impulse(to_center.normalized(), pull_strength)

	if dist <= damage_radius:
		for area in hitbox.get_overlapping_areas():
			if area is Hurtbox:
				area.receive_hit(hitbox)
