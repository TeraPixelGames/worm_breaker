extends AudioStreamPlayer

@export var base_frequency: float = 380.0
@export var combo_step: float = 1.1
@export var tone_seconds: float = 0.09
@export var amplitude: float = 0.3
@export var mix_rate: float = 44100.0

func _ready() -> void:
	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.buffer_length = 0.3
	generator.mix_rate = mix_rate
	stream = generator

func play_combo(combo: int) -> void:
	if combo < 1:
		return

	if not playing:
		play()
	var playback: AudioStreamGeneratorPlayback = get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var frequency: float = base_frequency * pow(combo_step, float(combo - 1))
	var frame_count: int = int(mix_rate * tone_seconds)
	for i in range(frame_count):
		var t: float = float(i) / mix_rate
		var envelope: float = exp(-18.0 * t)
		var sample: float = sin(TAU * frequency * t) * envelope * amplitude
		playback.push_frame(Vector2(sample, sample))
