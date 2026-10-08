class_name PoisonZone
extends Node3D
## A lingering ground hazard that ticks damage repeatedly while the player
## stands in it, instead of GroundHazard's single hit. Manually polls
## overlap on each tick rather than relying on area_entered, since that
## signal only fires once per continuous overlap.

@export var windup_time: float = 0.8
@export var duration: float = 4.0
@export var tick_interval: float = 1.0
@export var damage_per_tick: float = 6.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var hitbox: Hitbox = $Hitbox

var _windup_timer: float = 0.0
var _duration_timer: float = 0.0
var _tick_timer: float = 0.0
var _active: bool = false

func detonate_at(pos: Vector3) -> void:
	global_position = pos
	_windup_timer = windup_time
	_duration_timer = duration
	_tick_timer = 0.0
	_active = false
	hitbox.damage = damage_per_tick
	hitbox.monitoring = false
	mesh.scale = Vector3(0.15, 1.0, 0.15)

func _physics_process(delta: float) -> void:
	if not _active:
		_windup_timer -= delta
		var t: float = 1.0 - clamp(_windup_timer / windup_time, 0.0, 1.0)
		var s: float = lerp(0.15, 1.0, t)
		mesh.scale = Vector3(s, 1.0, s)
		if _windup_timer <= 0.0:
			_active = true
			hitbox.monitoring = true
			_tick_timer = 0.0
	else:
		_duration_timer -= delta
		if _duration_timer <= 0.0:
			queue_free()
			return
		_tick_timer -= delta
		if _tick_timer <= 0.0:
			_tick_timer = tick_interval
			_apply_tick()

func _apply_tick() -> void:
	for area in hitbox.get_overlapping_areas():
		if area is Hurtbox:
			area.receive_hit(hitbox)
