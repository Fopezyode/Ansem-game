extends Node
## Autoload. Adaptive music system: a phase-driven drone that intensifies as
## GameProgression advances, a heartbeat cue below 20% player HP, a victory
## sting once all champions fall, and a silence hook for future attacks
## (e.g. Market's "Blackout", not yet built).
##
## No composed music exists yet, so every track here is a procedurally
## synthesized placeholder tone — the ADAPTIVE SYSTEM is real and complete;
## only the audio content is a stand-in, exactly like the primitive-shape
## visuals stand in for real art. Swap _generate_tone's caller for real
## AudioStream assets whenever music is composed.

const MIX_RATE := 44100

const PHASE_FREQUENCIES := [60.0, 70.0, 85.0, 100.0, 130.0]
const PHASE_VOLUMES := [-24.0, -21.0, -18.0, -15.0, -10.0]

var _drone_player: AudioStreamPlayer
var _heartbeat_player: AudioStreamPlayer
var _player_health: HealthComponent = null
var _heartbeat_active: bool = false

func _ready() -> void:
	_drone_player = AudioStreamPlayer.new()
	_heartbeat_player = AudioStreamPlayer.new()
	add_child(_drone_player)
	add_child(_heartbeat_player)

	_drone_player.stream = _generate_tone(PHASE_FREQUENCIES[0], 12.0)
	_drone_player.volume_db = PHASE_VOLUMES[0]
	_drone_player.play()

	_heartbeat_player.stream = _generate_heartbeat()
	_heartbeat_player.volume_db = -3.0

	GameProgression.phase_changed.connect(_on_phase_changed)
	GameProgression.all_champions_defeated.connect(_on_all_champions_defeated)
	GameProgression.game_won.connect(_on_game_won)

func register_player(player: Node) -> void:
	_player_health = player.get_node("Health")
	_player_health.health_changed.connect(_on_player_health_changed)

func set_silenced(silenced: bool) -> void:
	_drone_player.stream_paused = silenced
	_heartbeat_player.stream_paused = silenced

func _on_phase_changed(phase_index: int, _label: String) -> void:
	var idx: int = clamp(phase_index, 0, PHASE_FREQUENCIES.size() - 1)
	_drone_player.stream = _generate_tone(PHASE_FREQUENCIES[idx], 12.0)
	_drone_player.volume_db = PHASE_VOLUMES[idx] - (6.0 if _heartbeat_active else 0.0)
	_drone_player.play()

func _on_all_champions_defeated() -> void:
	_heartbeat_player.stop()
	_heartbeat_active = false
	_drone_player.stream = _generate_tone(220.0, 8.0)
	_drone_player.volume_db = -12.0
	_drone_player.play()

## The true ending (Market defeated). Distinct from every other cue: a
## swelling major triad rather than another single-tone drone, so it reads
## as a resolved, triumphant finish instead of just another phase shift.
func _on_game_won() -> void:
	_heartbeat_player.stop()
	_heartbeat_active = false
	_drone_player.stream = _generate_victory_chord()
	_drone_player.volume_db = -6.0
	_drone_player.play()

func _on_player_health_changed(current: float, max_h: float) -> void:
	var low_health: bool = max_h > 0.0 and current > 0.0 and (current / max_h) < 0.2
	if low_health and not _heartbeat_active:
		_heartbeat_active = true
		_heartbeat_player.play()
		_drone_player.volume_db -= 6.0
	elif not low_health and _heartbeat_active:
		_heartbeat_active = false
		_heartbeat_player.stop()
		_drone_player.volume_db += 6.0

## A soft, slowly-swelling ambient pad rather than a flat buzzing tone:
## two slightly-detuned oscillators (a gentle chorus/beating effect) under
## one full fade-in/fade-out envelope per loop, so it breathes instead of
## droning continuously.
func _generate_tone(freq: float, loop_seconds: float) -> AudioStreamWAV:
	var sample_count: int = int(MIX_RATE * loop_seconds)
	var detune: float = freq * 1.006
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t: float = float(i) / MIX_RATE
		var loop_phase: float = float(i) / sample_count
		var envelope: float = sin(loop_phase * PI)
		var wave: float = (sin(t * TAU * freq) + sin(t * TAU * detune)) * 0.5
		var sample: float = wave * envelope * 0.35
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

## Layers a low thump (felt on subwoofers/headphones) under a short mid-range
## click (an attack transient small laptop speakers can actually reproduce,
## since they typically roll off well before the ~55-90 Hz thump band).
## Same breathing envelope as _generate_tone, but three detuned-free sine
## oscillators summed into an A-major triad (A3/C#4/E4) instead of one note,
## so the victory cue is clearly a resolved chord, not another drone.
func _generate_victory_chord() -> AudioStreamWAV:
	var freqs := [220.0, 277.18, 329.63]
	var loop_seconds := 6.0
	var sample_count: int = int(MIX_RATE * loop_seconds)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t: float = float(i) / MIX_RATE
		var loop_phase: float = float(i) / sample_count
		var envelope: float = sin(loop_phase * PI)
		var wave: float = 0.0
		for f in freqs:
			wave += sin(t * TAU * f)
		wave /= freqs.size()
		var sample: float = wave * envelope * 0.6
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

func _generate_heartbeat() -> AudioStreamWAV:
	var thump_duration := 0.14
	var total_duration := 0.8
	var sample_count: int = int(MIX_RATE * total_duration)
	var thump_samples: int = int(MIX_RATE * thump_duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var value := 0
		if i < thump_samples:
			var t: float = float(i) / MIX_RATE
			var envelope: float = pow(1.0 - (float(i) / thump_samples), 1.5)
			var thump: float = sin(t * TAU * 90.0)
			var click: float = sin(t * TAU * 620.0) * exp(-t * 45.0)
			var sample: float = (thump * 0.6 + click * 0.4) * envelope
			value = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
