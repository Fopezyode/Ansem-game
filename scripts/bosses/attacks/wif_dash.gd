class_name WifDashAttack
extends BossAttack
## Wif telegraphs briefly, then rapidly dashes in a straight line through
## the player's position, damaging anything caught in the path. Unlike the
## other bosses, Wif actually relocates — "Speed" is the whole point.
## Leaves a trail of afterimages so the dash reads as motion, not a teleport.
## Fully phase-driven (not create_timer waits) so it can be interrupted
## cleanly at any point by a well-timed Bull Charge.

signal finished

const AfterimageScript := preload("res://scripts/core/afterimage.gd")

@export var telegraph_time: float = 0.9
@export var dash_speed: float = 18.0
@export var dash_distance: float = 12.0
@export var damage: float = 18.0
@export var afterimage_interval: float = 0.04

enum Phase { INACTIVE, TELEGRAPH, DASHING }
var _phase: Phase = Phase.INACTIVE
var _timer: float = 0.0

var _boss: Node3D = null
var _boss_visual: Node3D = null
var _hitbox: Hitbox = null
var _dash_dir: Vector3 = Vector3.FORWARD
var _dash_remaining: float = 0.0
var _afterimage_timer: float = 0.0

func execute(boss: Node) -> void:
	_boss = boss
	_boss_visual = boss.get_node("Visual")
	_hitbox = boss.get_node("DashHitbox")
	var player: Node = boss.get_player()

	var to_player: Vector3 = player.global_position - boss.global_position
	to_player.y = 0.0
	_dash_dir = to_player.normalized() if to_player.length() > 0.01 else Vector3.FORWARD

	_hitbox.damage = damage
	_hitbox.reset_hits()
	_hitbox.monitoring = false

	_phase = Phase.TELEGRAPH
	_timer = telegraph_time
	await finished

func interrupt() -> void:
	if _phase == Phase.INACTIVE:
		return
	_phase = Phase.INACTIVE
	_hitbox.monitoring = false
	finished.emit()

func _physics_process(delta: float) -> void:
	match _phase:
		Phase.TELEGRAPH:
			_timer -= delta
			if _timer <= 0.0:
				_phase = Phase.DASHING
				_dash_remaining = dash_distance
				_afterimage_timer = 0.0
				_hitbox.monitoring = true
				_spawn_afterimage()
		Phase.DASHING:
			var step: float = min(dash_speed * delta, _dash_remaining)
			_boss.global_position += _dash_dir * step
			_dash_remaining -= step

			_afterimage_timer -= delta
			if _afterimage_timer <= 0.0:
				_afterimage_timer = afterimage_interval
				_spawn_afterimage()

			if _dash_remaining <= 0.0:
				_phase = Phase.INACTIVE
				_hitbox.monitoring = false
				finished.emit()
		Phase.INACTIVE:
			pass

func _spawn_afterimage() -> void:
	var ghost: Node3D = _boss.get_visual_clone()
	ghost.set_script(AfterimageScript)
	_boss.get_tree().current_scene.add_child(ghost)
	ghost.global_transform = _boss_visual.global_transform
