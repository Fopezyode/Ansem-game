class_name PumpChampion
extends ChampionBase
## PUMP: relentless pressure, constant movement. Unlike the other three
## champions, Pump doesn't just stand and wait between attacks — it walks
## toward the player continuously. If left unengaged for too long, it
## regenerates (a self-contained stand-in for "the Market regenerates" from
## the design doc, until champion fights are wired into a shared Market
## health pool by the full game flow).

@export_group("Chase")
@export var chase_speed: float = 3.5
@export var chase_stop_distance: float = 3.0

@export_group("Regeneration")
@export var regen_delay: float = 6.0
@export var regen_rate: float = 15.0

var _time_since_damaged: float = 0.0

func _ready() -> void:
	super._ready()
	health.damaged.connect(_on_damaged)

func _process(delta: float) -> void:
	super._process(delta)
	if state == State.INTRO or state == State.DEFEATED:
		return
	_chase_player(delta)
	_process_regen(delta)

func _on_damaged(_amount: float) -> void:
	_time_since_damaged = 0.0

func _chase_player(delta: float) -> void:
	if state == State.ATTACKING:
		return
	var player := get_player()
	if player == null:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > chase_stop_distance:
		global_position += to_player.normalized() * chase_speed * delta

func _process_regen(delta: float) -> void:
	_time_since_damaged += delta
	if _time_since_damaged >= regen_delay:
		health.heal(regen_rate * delta)

func _grant_core() -> void:
	get_player().grant_velocity_core()
