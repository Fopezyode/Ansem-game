class_name TrumpChampion
extends ChampionBase
## TRUMP: arena-control champion. Freed rather than killed — grants the
## Control Core, which lets Bull Charge shatter breakable walls.

func _grant_core() -> void:
	get_player().grant_control_core()
