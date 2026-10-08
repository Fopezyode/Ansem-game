class_name BossBase
extends Node3D
## Shared shell for every boss/champion fight: health, hurtbox, intro
## cutscene, idle motion, weighted-random attack selection (with a chance to
## chain two attacks back to back), evasive dodging against incoming
## charges/ultimates, and a charge-interrupt punish. Concrete bosses
## (MarketBoss, PepeChampion, ...) override `_on_defeated()` for their
## specific outcome (freeze in place vs. "freed" + Core reward).

signal intro_finished
signal defeated

enum State { INTRO, IDLE, ATTACKING, DEFEATED }

@export var player_path: NodePath
@export var display_name: String = ""
@export var intro_duration: float = 3.0
## Disable when multiple bosses share a test scene, so their intros don't
## fight over the player's camera/input at the same time.
@export var play_intro: bool = true
## Disable when an external director (e.g. EncounterDirector) controls when
## this fight actually begins, instead of it starting the moment it's ready.
@export var auto_start: bool = true

@export_group("Idle Motion")
@export var idle_bob_height: float = 0.3
@export var idle_bob_speed: float = 0.6
@export var idle_rotate_speed: float = 0.15

@export_group("Attack Pacing")
@export var first_attack_delay: float = 1.2
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 2.0
## Chance to immediately start another attack with no idle gap at all —
## keeps the pacing from ever feeling like a strict metronome.
@export var chain_attack_chance: float = 0.3

@export_group("Evasion")
## Off by default (Market, e.g., is "never walks" by design). Champions
## that should sidestep incoming charges/ultimates opt in per-scene.
@export var can_dodge_charges: bool = false
@export var dodge_chance: float = 0.35
@export var dodge_sense_radius: float = 7.0
@export var dodge_distance: float = 3.0
@export var dodge_cooldown: float = 4.0
## Caps how far from arena center dodges can push the boss, so a long
## fight full of dodges can never walk it into the boundary wall.
@export var dodge_max_radius: float = 15.0

@export_group("Interrupt")
@export var interrupt_bonus_damage: float = 15.0

@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: Node3D = $Visual
@onready var intro_camera: Camera3D = $IntroCamera
@onready var attacks_container: Node = $Attacks
@onready var health_label: Label3D = $HealthLabel

var state: State = State.INTRO

var _player: Node = null
var _player_camera: Camera3D = null
var _idle_time: float = 0.0
var _attack_timer: float = 0.0
var _attacks: Array[BossAttack] = []
var _last_attack: BossAttack = null
var _dodge_cooldown_timer: float = 0.0

## Guards against overlapping position tweens (evasive dodge, and any
## subclass-specific repositioning like Pepe's relocation hops) fighting
## over the same transform in the same frame.
var _is_repositioning: bool = false

func _ready() -> void:
	hurtbox.health_component = health
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)
	_player = get_node(player_path)
	_player_camera = _player.get_node("CameraPivot/SpringArm3D/Camera3D")
	for child in attacks_container.get_children():
		if child is BossAttack:
			_attacks.append(child)

	if auto_start:
		begin_encounter()

## Kicks off this fight: either the intro cutscene or straight to idle.
## Called automatically unless `auto_start` is off, in which case an
## external director (EncounterDirector) calls it when it's this boss's turn.
func begin_encounter() -> void:
	if play_intro:
		_start_intro()
	else:
		state = State.IDLE
		_attack_timer = first_attack_delay

func get_player() -> Node:
	return _player

func get_visual_clone() -> Node3D:
	return visual.duplicate()

func _on_health_changed(current: float, max_h: float) -> void:
	health_label.text = "%d / %d" % [int(current), int(max_h)]

func _process(delta: float) -> void:
	if state == State.INTRO or state == State.DEFEATED:
		return

	_idle_time += delta
	visual.position.y = sin(_idle_time * idle_bob_speed * TAU) * idle_bob_height
	visual.rotation.y += idle_rotate_speed * delta

	if can_dodge_charges:
		_dodge_cooldown_timer -= delta
		_check_evasive_dodge()

	if state == State.IDLE:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_begin_attack()

func _start_intro() -> void:
	state = State.INTRO
	_player.input_locked = true
	intro_camera.current = true
	await get_tree().create_timer(intro_duration).timeout
	_end_intro()

func _end_intro() -> void:
	_player_camera.current = true
	_player.input_locked = false
	state = State.IDLE
	_attack_timer = first_attack_delay
	intro_finished.emit()

func _begin_attack() -> void:
	if _attacks.is_empty():
		return
	state = State.ATTACKING
	var attack := _choose_attack()
	_last_attack = attack
	await attack.execute(self)
	if state == State.DEFEATED:
		return
	if _attacks.size() > 1 and randf() < chain_attack_chance:
		_begin_attack()
	else:
		state = State.IDLE
		_attack_timer = randf_range(idle_time_min, idle_time_max)

func _choose_attack() -> BossAttack:
	var candidates := _attacks
	if _attacks.size() > 1:
		candidates = _attacks.filter(func(a): return a != _last_attack)

	var total_weight := 0.0
	for a in candidates:
		total_weight += a.weight

	var roll := randf() * total_weight
	for a in candidates:
		roll -= a.weight
		if roll <= 0.0:
			return a
	return candidates[-1]

## Called by the player when a Bull Charge/Ultimate lands while this boss is
## mid-attack — a reward for aggressive, well-timed play instead of just
## tanking through everything. Attacks that support it get cut short.
func try_interrupt() -> void:
	if state != State.ATTACKING or health.is_dead():
		return
	if _last_attack and _last_attack.has_method("interrupt"):
		_last_attack.interrupt()
	health.take_damage(interrupt_bonus_damage)

## Occasionally sidesteps when it senses the player charging/ulting
## straight at it — not every time, so a charge still lands often enough to
## feel worth committing to.
func _check_evasive_dodge() -> void:
	if _dodge_cooldown_timer > 0.0 or state == State.ATTACKING or _is_repositioning:
		return
	if _player == null or not _player.has_method("is_charging_or_ulting"):
		return
	if not _player.is_charging_or_ulting():
		return

	var to_self: Vector3 = global_position - _player.global_position
	to_self.y = 0.0
	if to_self.length() > dodge_sense_radius:
		return

	var player_vel: Vector3 = _player.velocity
	player_vel.y = 0.0
	if player_vel.length() < 0.1:
		return
	if player_vel.normalized().dot(to_self.normalized()) < 0.5:
		return

	_dodge_cooldown_timer = dodge_cooldown
	if randf() > dodge_chance:
		return
	_perform_evasive_dodge(to_self)

func _perform_evasive_dodge(to_player: Vector3) -> void:
	var side := to_player.normalized().cross(Vector3.UP)
	if side.length() < 0.01:
		side = Vector3.RIGHT
	side = side.normalized()
	var target_pos := global_position + side * dodge_distance

	var flat := Vector2(target_pos.x, target_pos.z)
	if flat.length() > dodge_max_radius:
		flat = flat.normalized() * dodge_max_radius
		target_pos.x = flat.x
		target_pos.z = flat.y

	_is_repositioning = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _is_repositioning = false)

func _on_died() -> void:
	state = State.DEFEATED
	defeated.emit()
	_play_defeat_feedback()
	_on_defeated()

## Shared across every boss/champion, regardless of their specific defeat
## outcome (freed + Core vs. the Market's cleanse) — hit-stop lands right as
## the kill registers, which also nicely drags out the very start of
## whatever vanish/cleanse tween _on_defeated() kicks off next.
func _play_defeat_feedback() -> void:
	if _player == null:
		return
	if _player.has_method("hit_stop"):
		_player.hit_stop(0.15)
	if "camera_pivot" in _player:
		_player.camera_pivot.add_trauma(0.6)
	Sfx.play("defeat")

## Override in subclasses for boss-specific defeat behavior.
func _on_defeated() -> void:
	pass
