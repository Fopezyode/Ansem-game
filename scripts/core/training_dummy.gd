extends StaticBody3D
## Damageable target for testing Bull Charge / Ultimate output. Auto-revives
## after a short delay so it can be hit repeatedly during testing.

@export var respawn_delay: float = 2.0

@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var label: Label3D = $HealthLabel

var _respawn_timer: float = 0.0

func _ready() -> void:
	hurtbox.health_component = health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	_on_health_changed(health.max_health, health.max_health)

func _process(delta: float) -> void:
	if _respawn_timer <= 0.0:
		return
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		health.revive()

func _on_health_changed(current: float, max_h: float) -> void:
	label.text = "%d / %d" % [int(current), int(max_h)]

func _on_died() -> void:
	_respawn_timer = respawn_delay
	label.text = "DOWN"
