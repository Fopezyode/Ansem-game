class_name MarketBoss
extends BossBase
## THE MARKET: the final boss. Its attack pool (wired in market.tscn) reuses
## every freed champion's own attack scenes alongside its three signature
## ones (Milestone 4), so the final fight literally combines every mechanic
## the player has already learned to read. Deliberately excludes the two
## champion attacks that physically relocate their user (Pump's Lunge, Wif's
## Dash) — the Market "never walks, never chases, only manipulates the
## arena," per the design doc, even while absorbing their corruption.
##
## Unlike a champion (freed, then vanishes), the Market is cleansed: its
## corruption-green eyes fade to gold before it dissolves, and defeating it
## is the true ending rather than a Core reward.

@export var cleanse_time: float = 2.5

@onready var _eye_mat: StandardMaterial3D = $Visual/EyeLeft.get_surface_override_material(0)

func _on_defeated() -> void:
	hurtbox.set_deferred("monitorable", false)
	if _player:
		_player.input_locked = true
	_cleanse()
	GameProgression.notify_game_won()

func _cleanse() -> void:
	var eye_tween := create_tween()
	eye_tween.tween_property(_eye_mat, "emission", Color(1.0, 0.85, 0.3), cleanse_time * 0.6)
	eye_tween.parallel().tween_property(_eye_mat, "albedo_color", Color(1.0, 0.85, 0.3), cleanse_time * 0.6)

	var scale_tween := create_tween()
	scale_tween.tween_property(visual, "scale", Vector3(1.15, 1.15, 1.15), cleanse_time * 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(visual, "scale", Vector3.ZERO, cleanse_time * 0.65)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	scale_tween.tween_callback(func(): visible = false)
