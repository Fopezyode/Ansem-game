class_name ChampionBase
extends BossBase
## Shared "freed, not killed" behavior for the corrupted champions (Pepe,
## Trump, Wif, Pump). On defeat: stop being hittable, play a brief release
## animation, and grant this champion's Core to the player.

@export var vanish_time: float = 1.2

func _on_defeated() -> void:
	# This is usually reached from inside a Hitbox's own area_entered
	# dispatch (the killing blow), and Area3D forbids changing another
	# area's monitorable flag while the physics step is mid-dispatch —
	# must defer.
	hurtbox.set_deferred("monitorable", false)
	_grant_core()
	GameProgression.notify_champion_defeated()
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3.ZERO, vanish_time)
	tween.tween_callback(func(): visible = false)

## Override per champion to call the matching player.grant_*_core() method.
func _grant_core() -> void:
	pass
