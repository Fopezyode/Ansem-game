extends Node
## Autoload. Tracks overall game progression across the four champion
## fights and the Market's final phase, and broadcasts phase changes so the
## arena, HUD, and music can all react without needing direct references to
## each other.

signal phase_changed(phase_index: int, phase_label: String)
signal all_champions_defeated
signal game_won

const PHASE_LABELS := [
	"PHASE I: THE RUG",
	"PHASE II: THE FUD",
	"PHASE III: THE CAPITULATION",
	"PHASE IV: THE LAST BULL",
	"FINAL PHASE: SAVE THE TRENCHES",
]

var champions_defeated: int = 0
var current_phase_index: int = 0

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	phase_changed.emit(current_phase_index, PHASE_LABELS[current_phase_index])

func notify_champion_defeated() -> void:
	champions_defeated += 1
	# Champion defeats only cycle through Phases I-IV. The Final Phase is
	# entered explicitly via enter_final_phase() once the Market actually
	# appears, not the instant the fourth champion falls.
	if current_phase_index < PHASE_LABELS.size() - 2:
		current_phase_index += 1
		phase_changed.emit(current_phase_index, PHASE_LABELS[current_phase_index])
	if champions_defeated >= 4:
		all_champions_defeated.emit()

## Called by EncounterDirector right before the Market's fight begins.
func enter_final_phase() -> void:
	current_phase_index = PHASE_LABELS.size() - 1
	phase_changed.emit(current_phase_index, PHASE_LABELS[current_phase_index])

## Called by MarketBoss on defeat. The true ending.
func notify_game_won() -> void:
	game_won.emit()
