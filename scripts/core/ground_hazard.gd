class_name GroundHazard
extends Node3D
## A stationary, telegraphed ground hazard: grows/glows in place during
## windup, deals one hit while active, then despawns. Reused by any "the
## ground itself becomes dangerous" attack (Market Crash, Green Candle Rain,
## and later champion attacks like Trump's Ground Slam).

@export var windup_time: float = 1.0
@export var active_time: float = 0.4
@export var damage: float = 15.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var hitbox: Hitbox = $Hitbox

var _windup_timer: float = 0.0
var _active_timer: float = 0.0
var _active: bool = false

func detonate_at(pos: Vector3) -> void:
	global_position = pos
	_windup_timer = windup_time
	_active_timer = active_time
	_active = false
	hitbox.damage = damage
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
	else:
		_active_timer -= delta
		if _active_timer <= 0.0:
			queue_free()
