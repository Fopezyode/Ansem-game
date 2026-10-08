class_name WifChampion
extends ChampionBase
## WIF: speed-themed champion. Freed rather than killed — grants the
## Momentum Core, which permanently speeds up the Bull's dash.

func _grant_core() -> void:
	get_player().grant_momentum_core()
