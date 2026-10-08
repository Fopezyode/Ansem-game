class_name PepeChampion
extends ChampionBase
## PEPE: chaos-corrupted champion. Freed rather than killed — grants the
## Chaos Core, which gives the Bull's dash a trailing afterimage.
## Two kinds of motion: small in-place hops (just idle "he's alive" flavor)
## and larger relocation hops that actually move him to a new spot in the
## arena — otherwise the clones were the only thing that ever looked alive.

@export_group("Hop")
@export var hop_interval_min: float = 2.0
@export var hop_interval_max: float = 4.0
@export var hop_height: float = 0.6
@export var hop_duration: float = 0.35

@export_group("Relocation Hop")
@export var reloc_interval_min: float = 4.0
@export var reloc_interval_max: float = 7.0
@export var reloc_distance_min: float = 4.0
@export var reloc_distance_max: float = 7.0
@export var reloc_arena_radius: float = 14.0
@export var reloc_duration: float = 0.5

var _hop_timer: float = 0.0
var _reloc_timer: float = 0.0

func _ready() -> void:
	super._ready()
	_reset_hop_timer()
	_reset_reloc_timer()

func _process(delta: float) -> void:
	super._process(delta)
	if state == State.INTRO or state == State.DEFEATED or state == State.ATTACKING:
		return

	_reloc_timer -= delta
	if _reloc_timer <= 0.0:
		_reset_reloc_timer()
		_do_relocation_hop()
		return

	_hop_timer -= delta
	if _hop_timer <= 0.0 and not _is_repositioning:
		_reset_hop_timer()
		_do_hop()

func _reset_hop_timer() -> void:
	_hop_timer = randf_range(hop_interval_min, hop_interval_max)

func _reset_reloc_timer() -> void:
	_reloc_timer = randf_range(reloc_interval_min, reloc_interval_max)

func _do_hop() -> void:
	# Hops the whole body (root position), separate from the base class's
	# own idle bob on the Visual child, so the two animations never fight
	# over the same property.
	var tween := create_tween()
	tween.tween_property(self, "position:y", hop_height, hop_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", 0.0, hop_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

## A real hop to a new nearby spot in the arena, not just an in-place
## bounce, so Pepe actually moves around instead of only his clones doing so.
func _do_relocation_hop() -> void:
	if _is_repositioning:
		return
	var angle := randf() * TAU
	var dist := randf_range(reloc_distance_min, reloc_distance_max)
	var target := global_position + Vector3(sin(angle) * dist, 0.0, cos(angle) * dist)

	var flat := Vector2(target.x, target.z)
	if flat.length() > reloc_arena_radius:
		flat = flat.normalized() * reloc_arena_radius
		target.x = flat.x
		target.z = flat.y

	_is_repositioning = true
	var tween := create_tween()
	tween.tween_property(self, "global_position:y", hop_height * 1.5, reloc_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "global_position:x", target.x, reloc_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "global_position:z", target.z, reloc_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position:y", 0.0, reloc_duration * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): _is_repositioning = false)

func _grant_core() -> void:
	get_player().grant_chaos_core()
