extends Node3D
## Development-only harness: periodically fires a TelegraphedProjectile at the
## player so dash i-frames, parry timing, and damage can be verified before
## any real boss exists. Not part of the shipped boss framework (Milestone 3+).

const ProjectileScene := preload("res://scenes/core/telegraphed_projectile.tscn")

@export var fire_interval: float = 3.0
@export var target_path: NodePath

var _timer: float = 0.0
@onready var _target: Node3D = get_node(target_path)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = fire_interval
		_fire()

func _fire() -> void:
	if not is_instance_valid(_target):
		return
	var projectile: TelegraphedProjectile = ProjectileScene.instantiate()
	get_tree().current_scene.add_child(projectile)
	# Aim at the target's torso height (hurtbox capsule center), not its feet,
	# so the shot is a fair aimed telegraph regardless of emitter height.
	var aim_point := _target.global_position + Vector3(0, 1.0, 0)
	var dir := aim_point - global_position
	projectile.launch(global_position, dir)
