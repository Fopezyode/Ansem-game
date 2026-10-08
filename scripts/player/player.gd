extends CharacterBody3D
## Ansem and the Black Bull, controlled as a single unit.
## Locomotion is camera-relative; combat actions (dash, bull charge, parry,
## ultimate) lock movement briefly and are mutually exclusive via a state enum.

signal dash_state_changed(on_cooldown: bool, remaining: float, max_cd: float)
signal ultimate_state_changed(on_cooldown: bool, remaining: float, max_cd: float)
signal parry_result(success: bool)

enum State { LOCOMOTION, DASH, CHARGE, PARRY, ULTIMATE }

@export_group("Movement")
@export var walk_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var acceleration: float = 22.0
@export var deceleration: float = 26.0
@export var turn_speed: float = 12.0

@export_group("Physics")
@export var gravity: float = 20.0

@export_group("Dash")
@export var dash_speed: float = 20.0
@export var dash_duration: float = 0.2
@export var dash_cooldown_time: float = 0.8

@export_group("Bull Charge")
@export var charge_speed: float = 16.0
@export var charge_duration: float = 0.35
@export var charge_cooldown_time: float = 1.5
@export var charge_damage: float = 18.0

@export_group("Parry")
@export var parry_window: float = 0.25
@export var parry_recovery: float = 0.35
@export var parry_slowmo_scale: float = 0.25
@export var parry_slowmo_duration: float = 0.35

@export_group("Ultimate")
@export var ultimate_cooldown_time: float = 25.0
@export var ultimate_damage: float = 45.0
@export var ultimate_speed: float = 24.0
@export var ultimate_duration: float = 0.6

@export_group("Chaos Core")
@export var afterimage_interval: float = 0.05

@export_group("Knockback")
@export var knockback_decay: float = 8.0

@export_group("Impact Feedback")
@export var hit_taken_trauma: float = 0.25
@export var charge_landed_trauma: float = 0.35
@export var ultimate_landed_trauma: float = 0.55
@export var parry_success_trauma: float = 0.15
@export var death_trauma: float = 0.6

const AfterimageScript := preload("res://scripts/core/afterimage.gd")
const ImpactBurstScene := preload("res://scenes/core/impact_burst.tscn")

@onready var camera_pivot: Node3D = $CameraPivot
@onready var bull_mesh: Node3D = $BullMesh
@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var charge_hitbox: Hitbox = $BullMesh/ChargeHitbox
@onready var ultimate_hitbox: Hitbox = $BullMesh/UltimateHitbox

var state: State = State.LOCOMOTION
var state_timer: float = 0.0
var facing_dir: Vector3 = Vector3.FORWARD

var dash_cooldown: float = 0.0
var charge_cooldown: float = 0.0
var ultimate_cooldown: float = 0.0

var _action_velocity: Vector3 = Vector3.ZERO
var _parry_recovering: bool = false
var _time_scale_locks: int = 0
var _spawn_position: Vector3

## Set by cutscenes (boss intro, phase transitions) to hold the player still
## and ignore all ability input without disrupting the state machine.
var input_locked: bool = false

## Core upgrades. Each is granted permanently by freeing the matching
## champion (Milestones 5-8).
var has_chaos_core: bool = false
var has_control_core: bool = false
var has_momentum_core: bool = false
var has_velocity_core: bool = false
var _afterimage_timer: float = 0.0

## External push/pull (wind gusts, tornadoes). Decays on its own each frame
## and blends additively with whatever the state machine wants, so it never
## has to know about knockback sources.
var _knockback_velocity: Vector3 = Vector3.ZERO

func grant_chaos_core() -> void:
	has_chaos_core = true

func grant_control_core() -> void:
	has_control_core = true

func grant_momentum_core() -> void:
	has_momentum_core = true
	dash_speed *= 1.4

func grant_velocity_core() -> void:
	has_velocity_core = true
	walk_speed *= 1.25
	sprint_speed *= 1.25

func apply_impulse(dir: Vector3, strength: float) -> void:
	_knockback_velocity = dir.normalized() * strength

## Lets bosses sense an incoming charge/ultimate to decide whether to dodge.
func is_charging_or_ulting() -> bool:
	return state == State.CHARGE or state == State.ULTIMATE

## Full reset between sequential fights (EncounterDirector): heals to max
## and clears cooldowns, so the next champion starts on a clean slate.
func full_restore() -> void:
	health.invulnerable = false
	health.revive()
	dash_cooldown = 0.0
	charge_cooldown = 0.0
	ultimate_cooldown = 0.0

func _ready() -> void:
	_spawn_position = global_position
	hurtbox.health_component = health
	hurtbox.parried_attack.connect(_on_parry_success)
	charge_hitbox.monitoring = false
	charge_hitbox.damage = charge_damage
	charge_hitbox.landed_hit.connect(_on_charge_landed)
	ultimate_hitbox.monitoring = false
	ultimate_hitbox.damage = ultimate_damage
	ultimate_hitbox.landed_hit.connect(_on_ultimate_landed)
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	MusicController.register_player(self)

func _unhandled_input(event: InputEvent) -> void:
	# Test-only convenience: there's no real death/retry flow yet (that belongs
	# with the boss fights in later milestones), so let testers reset here.
	if health.is_dead() and event.is_action_pressed("debug_respawn"):
		_respawn()

func _respawn() -> void:
	global_position = _spawn_position
	velocity = Vector3.ZERO
	state = State.LOCOMOTION
	_parry_recovering = false
	dash_cooldown = 0.0
	charge_cooldown = 0.0
	ultimate_cooldown = 0.0
	health.invulnerable = false
	health.revive()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_tick_cooldowns(delta)
	_apply_gravity(delta)

	match state:
		State.LOCOMOTION:
			if input_locked:
				_process_locked(delta)
			else:
				_process_locomotion(delta)
				_check_action_inputs()
		State.DASH:
			_process_dash(delta)
		State.CHARGE:
			_process_charge(delta)
		State.PARRY:
			_process_parry(delta)
		State.ULTIMATE:
			_process_ultimate(delta)

	velocity.x += _knockback_velocity.x
	velocity.z += _knockback_velocity.z
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)

	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

func _process_locomotion(delta: float) -> void:
	var input_vec := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	var cam_basis := camera_pivot.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir := forward * input_vec.y + right * input_vec.x
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	var is_sprinting := Input.is_action_pressed("sprint") and move_dir.length() > 0.01
	var target_speed := sprint_speed if is_sprinting else walk_speed
	var target_velocity := move_dir * target_speed

	var accel := acceleration if move_dir.length() > 0.01 else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

	if move_dir.length() > 0.01:
		facing_dir = move_dir
		var target_yaw := atan2(move_dir.x, move_dir.z)
		bull_mesh.rotation.y = lerp_angle(bull_mesh.rotation.y, target_yaw, turn_speed * delta)
	else:
		facing_dir = forward

func _process_locked(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

func _check_action_inputs() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		_start_dash()
	elif Input.is_action_just_pressed("bull_charge") and charge_cooldown <= 0.0:
		_start_charge()
	elif Input.is_action_just_pressed("parry"):
		_start_parry()
	elif Input.is_action_just_pressed("ultimate") and ultimate_cooldown <= 0.0:
		_start_ultimate()

func _tick_cooldowns(delta: float) -> void:
	dash_cooldown = max(dash_cooldown - delta, 0.0)
	charge_cooldown = max(charge_cooldown - delta, 0.0)
	ultimate_cooldown = max(ultimate_cooldown - delta, 0.0)
	dash_state_changed.emit(dash_cooldown > 0.0, dash_cooldown, dash_cooldown_time)
	ultimate_state_changed.emit(ultimate_cooldown > 0.0, ultimate_cooldown, ultimate_cooldown_time)

## --- Dash ---

func _start_dash() -> void:
	state = State.DASH
	state_timer = dash_duration
	dash_cooldown = dash_cooldown_time
	health.invulnerable = true
	_action_velocity = facing_dir.normalized() * dash_speed
	_afterimage_timer = 0.0
	Sfx.play("dash")
	if has_chaos_core:
		_spawn_afterimage()

func _process_dash(delta: float) -> void:
	velocity.x = _action_velocity.x
	velocity.z = _action_velocity.z
	if has_chaos_core:
		_afterimage_timer -= delta
		if _afterimage_timer <= 0.0:
			_afterimage_timer = afterimage_interval
			_spawn_afterimage()
	state_timer -= delta
	if state_timer <= 0.0:
		health.invulnerable = false
		velocity.x = 0.0
		velocity.z = 0.0
		state = State.LOCOMOTION

## --- Bull Charge ---

func _start_charge() -> void:
	state = State.CHARGE
	state_timer = charge_duration
	charge_cooldown = charge_cooldown_time
	charge_hitbox.reset_hits()
	charge_hitbox.monitoring = true
	_action_velocity = facing_dir.normalized() * charge_speed
	bull_mesh.rotation.y = atan2(facing_dir.x, facing_dir.z)

func _process_charge(delta: float) -> void:
	velocity.x = _action_velocity.x
	velocity.z = _action_velocity.z
	state_timer -= delta
	if state_timer <= 0.0:
		charge_hitbox.monitoring = false
		velocity.x = 0.0
		velocity.z = 0.0
		state = State.LOCOMOTION

func _on_charge_landed(hurtbox: Hurtbox) -> void:
	hit_stop(0.05)
	camera_pivot.add_trauma(charge_landed_trauma)
	Sfx.play("impact_heavy")
	_spawn_impact_burst(hurtbox.global_position, Color(0.1, 1.0, 0.4))
	var target := hurtbox.get_parent()
	if target and target.has_method("try_interrupt"):
		target.try_interrupt()

## --- Parry ---

func _start_parry() -> void:
	state = State.PARRY
	state_timer = parry_window
	_parry_recovering = false
	hurtbox.is_parrying = true
	velocity.x = 0.0
	velocity.z = 0.0

func _process_parry(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	state_timer -= delta
	if state_timer > 0.0:
		return
	if not _parry_recovering:
		hurtbox.is_parrying = false
		_parry_recovering = true
		state_timer = parry_recovery
		parry_result.emit(false)
	else:
		state = State.LOCOMOTION
		_parry_recovering = false

func _on_parry_success(_hitbox: Hitbox) -> void:
	if state != State.PARRY:
		return
	hurtbox.is_parrying = false
	_parry_recovering = false
	state = State.LOCOMOTION
	parry_result.emit(true)
	camera_pivot.add_trauma(parry_success_trauma)
	Sfx.play("parry")
	_push_time_scale(parry_slowmo_scale, parry_slowmo_duration)

## --- Ultimate: Bull Stampede ---

func _start_ultimate() -> void:
	state = State.ULTIMATE
	state_timer = ultimate_duration
	ultimate_cooldown = ultimate_cooldown_time
	health.invulnerable = true
	ultimate_hitbox.reset_hits()
	ultimate_hitbox.monitoring = true
	_action_velocity = facing_dir.normalized() * ultimate_speed
	bull_mesh.rotation.y = atan2(facing_dir.x, facing_dir.z)
	camera_pivot.add_trauma(0.2)
	camera_pivot.punch_zoom(-10.0, ultimate_duration + 0.3)

func _process_ultimate(delta: float) -> void:
	velocity.x = _action_velocity.x
	velocity.z = _action_velocity.z
	state_timer -= delta
	if state_timer <= 0.0:
		health.invulnerable = false
		ultimate_hitbox.monitoring = false
		velocity.x = 0.0
		velocity.z = 0.0
		state = State.LOCOMOTION

func _on_ultimate_landed(hurtbox: Hurtbox) -> void:
	hit_stop(0.1)
	camera_pivot.add_trauma(ultimate_landed_trauma)
	camera_pivot.punch_zoom(6.0, 0.3)
	Sfx.play("impact_heavy", 3.0)
	_spawn_impact_burst(hurtbox.global_position, Color(1.0, 0.75, 0.15))

## --- Shared feedback / death ---

func _on_damaged(_amount: float) -> void:
	camera_pivot.add_trauma(hit_taken_trauma)
	Sfx.play("impact_light")

func _spawn_impact_burst(pos: Vector3, tint: Color) -> void:
	var burst: ImpactBurst = ImpactBurstScene.instantiate()
	get_tree().current_scene.add_child(burst)
	burst.detonate_at(pos, tint)

## Public: called by BossBase on any boss/champion defeat, and internally on
## the player's own charge/ultimate impacts.
func hit_stop(duration: float) -> void:
	_push_time_scale(0.05, duration)

func _push_time_scale(scale: float, duration: float) -> void:
	_time_scale_locks += 1
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	_time_scale_locks -= 1
	if _time_scale_locks <= 0:
		Engine.time_scale = 1.0

func _spawn_afterimage() -> void:
	var ghost: Node3D = bull_mesh.duplicate()
	ghost.set_script(AfterimageScript)
	get_tree().current_scene.add_child(ghost)
	ghost.global_transform = bull_mesh.global_transform

func _on_died() -> void:
	set_physics_process(false)
	camera_pivot.add_trauma(death_trauma)
