extends Node
## Autoload. Procedural one-shot SFX for combat feedback (hits, dashes,
## parries, defeats), played through a small round-robin pool of
## AudioStreamPlayers so overlapping hits don't cut each other off.
##
## No sourced sound files exist yet, so — same disclaimer as
## MusicController's placeholder drone — every clip here is a synthesized
## stand-in: the PLAYBACK SYSTEM (pooling, generation, triggering) is real
## and complete; only the audio content is a stand-in for real sound design.

const MIX_RATE := 44100
const POOL_SIZE := 6

var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _clips: Dictionary = {}

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

	_clips["impact_light"] = _generate_impact(140.0, 0.09, 0.5)
	_clips["impact_heavy"] = _generate_impact(80.0, 0.22, 0.85)
	_clips["dash"] = _generate_whoosh()
	_clips["parry"] = _generate_chime()
	_clips["defeat"] = _generate_defeat_stinger()

func play(clip_name: String, volume_db: float = 0.0) -> void:
	if not _clips.has(clip_name):
		return
	var p := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool.size()
	p.stream = _clips[clip_name]
	p.volume_db = volume_db
	p.play()

## A short pitch-dropping thump, with a touch of noise for "impact" bite.
## Lower base_freq / longer duration / higher amp reads as a bigger hit.
func _generate_impact(base_freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_count: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t: float = float(i) / MIX_RATE
		var progress: float = float(i) / sample_count
		var envelope: float = pow(1.0 - progress, 2.0)
		var freq: float = base_freq * (1.0 - progress * 0.5)
		var tone: float = sin(t * TAU * freq)
		var noise: float = (randf() * 2.0 - 1.0) * 0.25
		var sample: float = (tone * 0.75 + noise) * envelope * amp
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _to_stream(data, sample_count)

## A quick burst of enveloped noise — reads as air/motion, not a tone.
func _generate_whoosh() -> AudioStreamWAV:
	var duration := 0.22
	var sample_count: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var progress: float = float(i) / sample_count
		var envelope: float = sin(progress * PI)
		var noise: float = randf() * 2.0 - 1.0
		var sample: float = noise * envelope * 0.35
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _to_stream(data, sample_count)

## A bright two-note chime for a successful parry.
func _generate_chime() -> AudioStreamWAV:
	var duration := 0.35
	var sample_count: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var freqs := [880.0, 1318.5]
	for i in range(sample_count):
		var t: float = float(i) / MIX_RATE
		var progress: float = float(i) / sample_count
		var envelope: float = pow(1.0 - progress, 1.5)
		var wave: float = 0.0
		for f in freqs:
			wave += sin(t * TAU * f)
		wave /= freqs.size()
		var sample: float = wave * envelope * 0.5
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _to_stream(data, sample_count)

## A longer descending stinger for a boss/champion falling.
func _generate_defeat_stinger() -> AudioStreamWAV:
	var duration := 0.9
	var sample_count: int = int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t: float = float(i) / MIX_RATE
		var progress: float = float(i) / sample_count
		var envelope: float = pow(1.0 - progress, 1.2)
		var freq: float = lerp(220.0, 110.0, progress)
		var tone: float = sin(t * TAU * freq) + sin(t * TAU * freq * 1.5) * 0.5
		var sample: float = tone * envelope * 0.45
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _to_stream(data, sample_count)

func _to_stream(data: PackedByteArray, sample_count: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
