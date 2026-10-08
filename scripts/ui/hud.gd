extends CanvasLayer
## Minimal combat HUD: player HP, dash cooldown, ultimate cooldown, boss HP,
## and a phase banner that announces each overall game phase (Milestone 9+).
## The boss bar can retarget itself as champions come and go (EncounterDirector).

@export var player_path: NodePath
@export var boss_path: NodePath
@export var encounter_director_path: NodePath

@onready var _player: Node = get_node(player_path)
@onready var hp_bar: ProgressBar = $Margin/VBox/HPBar
@onready var dash_bar: ProgressBar = $Margin/VBox/CooldownRow/DashBox/DashBar
@onready var ult_bar: ProgressBar = $Margin/VBox/CooldownRow/UltBox/UltBar
@onready var boss_bar_container: Control = $TopBar
@onready var boss_bar: ProgressBar = $TopBar/VBox/BossBar
@onready var boss_label: Label = $TopBar/VBox/BossLabel
@onready var phase_banner: Label = $PhaseBanner
@onready var low_health_vignette: ColorRect = $LowHealthVignette
@onready var ending_backdrop: ColorRect = $EndingScreen/Backdrop
@onready var ending_label: Label = $EndingScreen/EndingLabel

var _bound_boss_health: HealthComponent = null
var _low_health_active: bool = false
var _vignette_tween: Tween = null

func _ready() -> void:
	var health: HealthComponent = _player.get_node("Health")
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)
	_player.dash_state_changed.connect(_on_dash_state_changed)
	_player.ultimate_state_changed.connect(_on_ultimate_state_changed)

	if not encounter_director_path.is_empty():
		get_node(encounter_director_path).champion_activated.connect(bind_boss)
		boss_bar_container.visible = false
	elif boss_path.is_empty():
		boss_bar_container.visible = false
	else:
		bind_boss(get_node(boss_path))

	phase_banner.modulate.a = 0.0
	GameProgression.phase_changed.connect(_on_phase_changed)
	GameProgression.game_won.connect(_on_game_won)

## Points the boss bar at a new boss (used directly, or via EncounterDirector
## when the active champion changes).
func bind_boss(boss: Node) -> void:
	if _bound_boss_health and _bound_boss_health.health_changed.is_connected(_on_boss_health_changed):
		_bound_boss_health.health_changed.disconnect(_on_boss_health_changed)

	var boss_health: HealthComponent = boss.get_node("Health")
	_bound_boss_health = boss_health
	boss_health.health_changed.connect(_on_boss_health_changed)
	_on_boss_health_changed(boss_health.current_health, boss_health.max_health)

	if "display_name" in boss and boss.display_name != "":
		boss_label.text = boss.display_name
	boss_bar_container.visible = true

func _on_phase_changed(_phase_index: int, phase_label: String) -> void:
	phase_banner.text = phase_label
	phase_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(phase_banner, "modulate:a", 1.0, 0.6)
	tween.tween_interval(2.2)
	tween.tween_property(phase_banner, "modulate:a", 0.0, 0.9)

func _on_health_changed(current: float, max_h: float) -> void:
	hp_bar.max_value = max_h
	hp_bar.value = current

	var low_health: bool = max_h > 0.0 and current > 0.0 and (current / max_h) < 0.2
	if low_health and not _low_health_active:
		_low_health_active = true
		_start_low_health_pulse()
	elif not low_health and _low_health_active:
		_low_health_active = false
		_stop_low_health_pulse()

## Pulses in sync with MusicController's heartbeat cue (0.8s cycle: a fast
## punch-in then a slow fade, like a heartbeat's lub-dub).
func _start_low_health_pulse() -> void:
	if _vignette_tween:
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.set_loops()
	_vignette_tween.tween_property(low_health_vignette, "material:shader_parameter/strength", 1.0, 0.12)
	_vignette_tween.tween_property(low_health_vignette, "material:shader_parameter/strength", 0.25, 0.68)

func _stop_low_health_pulse() -> void:
	if _vignette_tween:
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.tween_property(low_health_vignette, "material:shader_parameter/strength", 0.0, 0.4)

func _on_dash_state_changed(_on_cd: bool, remaining: float, max_cd: float) -> void:
	dash_bar.value = 1.0 - (remaining / max_cd if max_cd > 0.0 else 0.0)

func _on_ultimate_state_changed(_on_cd: bool, remaining: float, max_cd: float) -> void:
	ult_bar.value = 1.0 - (remaining / max_cd if max_cd > 0.0 else 0.0)

func _on_boss_health_changed(current: float, max_h: float) -> void:
	boss_bar.max_value = max_h
	boss_bar.value = current

func _on_game_won() -> void:
	if _vignette_tween:
		_vignette_tween.kill()
	low_health_vignette.material.set_shader_parameter("strength", 0.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ending_backdrop, "color:a", 0.75, 2.0)
	tween.tween_property(ending_label, "modulate:a", 1.0, 2.0).set_delay(0.6)
