class_name TelegraphedProjectile
extends Node3D
## A fair, clearly-telegraphed attack: it grows/glows in place during windup,
## then travels in a straight line until it hits something or expires.
## Generic on purpose — every boss/champion ranged attack (Milestones 4-10)
## reuses this instead of writing its own projectile logic.

@export var windup_time: float = 0.8
@export var travel_speed: float = 9.0
@export var lifetime: float = 6.0
@export var damage: float = 15.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var hitbox: Hitbox = $Hitbox

var _direction: Vector3 = Vector3.FORWARD
var _windup_timer: float = 0.0
var _traveling: bool = false
var _life_timer: float = 0.0

func launch(from: Vector3, direction: Vector3) -> void:
	global_position = from
	_direction = direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	_windup_timer = windup_time
	_traveling = false
	_life_timer = lifetime
	hitbox.damage = damage
	hitbox.monitoring = false
	mesh.scale = Vector3.ONE * 0.2

func _ready() -> void:
	hitbox.landed_hit.connect(func(_h): queue_free())

func _physics_process(delta: float) -> void:
	_life_timer -= delta
	if _life_timer <= 0.0:
		queue_free()
		return

	if not _traveling:
		_windup_timer -= delta
		var t: float = 1.0 - clamp(_windup_timer / windup_time, 0.0, 1.0)
		mesh.scale = Vector3.ONE * lerp(0.2, 1.0, t)
		if _windup_timer <= 0.0:
			_traveling = true
			hitbox.monitoring = true
	else:
		global_position += _direction * travel_speed * delta
