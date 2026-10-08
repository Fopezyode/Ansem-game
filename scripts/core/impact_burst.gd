class_name ImpactBurst
extends CPUParticles3D
## A short one-shot particle burst for combat impact feedback (hits landing,
## boss defeats). CPUParticles3D rather than GPUParticles3D — this project
## targets the GL Compatibility renderer for HTML5 export, where CPU
## particles are the safe, universally-supported choice. Self-frees once its
## emission finishes: same spawn-and-forget detonate_at() convention as
## GroundHazard/PoisonZone/Tornado.

func _ready() -> void:
	finished.connect(queue_free)

func detonate_at(pos: Vector3, tint: Color) -> void:
	global_position = pos
	color = tint
	emitting = true
