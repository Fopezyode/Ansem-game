class_name PumpLungeAttack
extends BossAttack
## A quick melee lunge, thrown out as soon as Pump is close — it doesn't
## wait around like the other bosses. Short telegraph on purpose.
## Fully phase-driven (not create_timer waits) so it can be interrupted
## cleanly at any point by a well-timed Bull Charge.

signal finished

@export var telegraph_time: float = 0.4
@export var lunge_speed: float = 14.0
@export var lunge_distance: float = 4.0
@export var damage: float = 15.0

enum Phase { INACTIVE, TELEGRAPH, LUNGING }
var _phase: Phase = Phase.INACTIVE
var _timer: float = 0.0

var _boss: Node3D = null
var _hitbox: Hitbox = null
var _dir: Vector3 = Vector3.FORWARD
var _remaining: float = 0.0

func execute(boss: Node) -> void:
	_boss = boss
	_hitbox = boss.get_node("LungeHitbox")
	var player: Node = boss.get_player()

	var to_player: Vector3 = player.global_position - boss.global_position
	to_player.y = 0.0
	_dir = to_player.normalized() if to_player.length() > 0.01 else Vector3.FORWARD

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
				_phase = Phase.LUNGING
				_remaining = lunge_distance
				_hitbox.monitoring = true
		Phase.LUNGING:
			var step: float = min(lunge_speed * delta, _remaining)
			_boss.global_position += _dir * step
			_remaining -= step
			if _remaining <= 0.0:
				_phase = Phase.INACTIVE
				_hitbox.monitoring = false
				finished.emit()
		Phase.INACTIVE:
			pass
