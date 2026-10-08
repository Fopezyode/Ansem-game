extends Node
## Sequences the four champion fights one at a time: only the current
## champion is active and visible; the rest sit dormant until their turn.
## Defeating one fully restores the player, then brings in the next with
## its own intro cutscene. This is what makes the shared test arena behave
## like the real game loop instead of "every boss live at once."

signal champion_activated(champion: Node)

@export var player_path: NodePath
@export var champion_paths: Array[NodePath] = []
@export var market_path: NodePath
@export var heal_delay: float = 1.5
## Beat held after the Final Phase banner/arena-evolution/music shift fire
## and before the Market itself actually appears, so the escalation reads
## before combat starts.
@export var final_phase_delay: float = 2.0

var _player: Node = null
var _champions: Array[Node] = []
var _current_index: int = -1

func _ready() -> void:
	_player = get_node(player_path)
	for path in champion_paths:
		_champions.append(get_node(path))

	# Wait a frame so every sibling's own _ready() (health/hurtbox wiring,
	# attack list population) has already run before we touch them.
	await get_tree().process_frame

	for champion in _champions:
		_deactivate(champion)

	if not market_path.is_empty():
		_deactivate(get_node(market_path))

	_advance()

func _deactivate(champion: Node) -> void:
	champion.visible = false
	champion.process_mode = Node.PROCESS_MODE_DISABLED
	var hurtbox: Hurtbox = champion.get_node("Hurtbox")
	hurtbox.monitorable = false

func _activate(champion: Node) -> void:
	champion.process_mode = Node.PROCESS_MODE_INHERIT
	champion.visible = true
	var hurtbox: Hurtbox = champion.get_node("Hurtbox")
	hurtbox.monitorable = true
	if not champion.defeated.is_connected(_on_current_defeated):
		champion.defeated.connect(_on_current_defeated, CONNECT_ONE_SHOT)
	champion.begin_encounter()
	champion_activated.emit(champion)

func _on_current_defeated() -> void:
	await get_tree().create_timer(heal_delay).timeout
	_player.full_restore()
	_advance()

func _advance() -> void:
	_current_index += 1
	if _current_index >= _champions.size():
		_begin_final_phase()
		return
	_activate(_champions[_current_index])

## All four champions freed: the player is already fully restored (by
## _on_current_defeated, just before this runs). Announce the Final Phase,
## hold a beat for the arena/music shift to land, then bring the Market in.
func _begin_final_phase() -> void:
	if market_path.is_empty():
		return
	GameProgression.enter_final_phase()
	await get_tree().create_timer(final_phase_delay).timeout
	_activate_market(get_node(market_path))

## Distinct from _activate: the Market has no "next fight" to queue up, so
## it doesn't wire the defeated -> _on_current_defeated sequencing champions
## use. MarketBoss handles its own defeat outcome (the true ending) directly.
func _activate_market(market: Node) -> void:
	market.process_mode = Node.PROCESS_MODE_INHERIT
	market.visible = true
	var hurtbox: Hurtbox = market.get_node("Hurtbox")
	hurtbox.monitorable = true
	market.begin_encounter()
	champion_activated.emit(market)
