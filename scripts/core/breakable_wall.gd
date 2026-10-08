class_name BreakableWall
extends StaticBody3D
## A temporary arena-control barrier: solid to everything until the player
## has the Control Core, at which point a Bull Charge shatters it instead of
## bouncing off. Rises from the ground (telegraph) before it's solid, and
## retracts on its own after `lifetime`. Used by Trump's Walls attack.

@export var rise_time: float = 0.5
@export var lifetime: float = 5.0

@onready var base: Node3D = $Base
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var break_detector: Area3D = $BreakDetector

var player: Node = null

enum Phase { RISING, SOLID, RETRACTING }
var _phase: Phase = Phase.RISING
var _timer: float = 0.0

func _ready() -> void:
	break_detector.area_entered.connect(_on_area_entered)
	collision.disabled = true
	break_detector.monitoring = false
	base.scale.y = 0.02
	_timer = rise_time

func _process(delta: float) -> void:
	match _phase:
		Phase.RISING:
			_timer -= delta
			var t: float = clamp(1.0 - _timer / rise_time, 0.0, 1.0)
			base.scale.y = lerp(0.02, 1.0, t)
			if _timer <= 0.0:
				_phase = Phase.SOLID
				_timer = lifetime
				collision.disabled = false
				break_detector.monitoring = true
		Phase.SOLID:
			_timer -= delta
			if _timer <= 0.0:
				_retract()
		Phase.RETRACTING:
			pass

func _on_area_entered(area: Area3D) -> void:
	if player == null or not (area is Hitbox):
		return
	var hitbox := area as Hitbox
	if hitbox.tag == "bull_charge" and player.has_control_core:
		_shatter()

func _shatter() -> void:
	_phase = Phase.RETRACTING
	collision.disabled = true
	# Called from _on_area_entered — Area3D forbids changing monitoring
	# synchronously inside its own signal callback, must defer.
	break_detector.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(base, "scale:y", 0.02, 0.15)
	tween.tween_callback(queue_free)

func _retract() -> void:
	_phase = Phase.RETRACTING
	collision.disabled = true
	break_detector.monitoring = false
	var tween := create_tween()
	tween.tween_property(base, "scale:y", 0.02, 0.6)
	tween.tween_callback(queue_free)
