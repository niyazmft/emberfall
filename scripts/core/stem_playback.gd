extends Node

## _StemPlayback
## Handles playback and real-time analysis of a single audio stem.
## Uses AudioEffectSpectrumAnalyzer for transient and feature detection.

class_name _StemPlayback

# ── Signals ────────────────────────────────────────────────────────────────
signal transient_detected(type: String, intensity: float)
signal feature_updated(feature_name: String, value: float)

# ── Constants ─────────────────────────────────────────────────────────────
const ANALYSIS_INTERVAL_SEC: float = 0.016  ## ~60Hz analysis
const MIN_DB: float = -60.0

# ── Properties ────────────────────────────────────────────────────────────
var stem_id: String = ""
var bus_name: String = ""
var audio_player: AudioStreamPlayer

var _analyzer: AudioEffectSpectrumAnalyzerInstance
var _bus_index: int = -1
var _last_analysis_time: float = 0.0

# --- Specific analysis state ---
var _prev_magnitude: float = 0.0
var _cooldown_timer: float = 0.0
var _climb_width: float = 0.0

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _init(p_stem_id: String, p_bus_name: String) -> void:
	stem_id = p_stem_id
	bus_name = p_bus_name

	audio_player = AudioStreamPlayer.new()
	audio_player.bus = bus_name
	add_child(audio_player)


func _ready() -> void:
	_setup_analyzer()


func _process(delta: float) -> void:
	if not audio_player.playing:
		return

	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)

	_last_analysis_time += delta
	if _last_analysis_time >= ANALYSIS_INTERVAL_SEC:
		_last_analysis_time = 0.0
		_analyze_audio()


# ── Public API ─────────────────────────────────────────────────────────────


func play_stream(stream: AudioStream) -> void:
	audio_player.stream = stream
	audio_player.play()


func stop() -> void:
	audio_player.stop()


# ── Internal ────────────────────────────────────────────────────────────────


func _setup_analyzer() -> void:
	_bus_index = AudioServer.get_bus_index(bus_name)
	if _bus_index == -1:
		push_error("_StemPlayback: Bus '%s' not found." % bus_name)
		return

	# Look for SpectrumAnalyzer effect
	for i: int in range(AudioServer.get_bus_effect_count(_bus_index)):
		var effect: AudioEffect = AudioServer.get_bus_effect(_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			var instance: AudioEffectInstance = AudioServer.get_bus_effect_instance(_bus_index, i)
			_analyzer = instance as AudioEffectSpectrumAnalyzerInstance
			break

	if not _analyzer:
		push_warning("_StemPlayback: No AudioEffectSpectrumAnalyzer found on bus '%s'." % bus_name)


func _analyze_audio() -> void:
	if not _analyzer:
		return

	match stem_id:
		"BD-BASS":
			_analyze_bass()
		"BD-MECH":
			_analyze_mech()
		"BD-STRESS":
			_analyze_stress()
		"BD-CLIMB":
			_analyze_climb()


func _analyze_bass() -> void:
	# BASS impact detection: look for sudden magnitude jump in low frequencies (e.g. 20-150Hz)
	var mag: float = _analyzer.get_magnitude_for_frequency_range(20, 150).length()
	var energy: float = linear_to_db(mag)

	if energy > -20.0 and (mag - _prev_magnitude) > 0.1 and _cooldown_timer <= 0.0:
		transient_detected.emit("impact", clampf((energy + 20.0) / 20.0, 0.0, 1.0))
		_cooldown_timer = 0.2  # 200ms cooldown

	_prev_magnitude = mag


func _analyze_mech() -> void:
	# MECH irregular clangs: mid-high frequencies (e.g. 1000-4000Hz)
	var mag: float = _analyzer.get_magnitude_for_frequency_range(1000, 4000).length()
	var energy: float = linear_to_db(mag)

	if energy > -25.0 and (mag - _prev_magnitude) > 0.05 and _cooldown_timer <= 0.0:
		transient_detected.emit("clang", clampf((energy + 25.0) / 25.0, 0.0, 1.0))
		_cooldown_timer = 0.15

	_prev_magnitude = mag


func _analyze_stress() -> void:
	# STRESS swells: overall magnitude trend
	var mag: float = _analyzer.get_magnitude_for_frequency_range(20, 20000).length()
	feature_updated.emit("swell", mag)

	if mag > _prev_magnitude + 0.1 and _cooldown_timer <= 0.0:
		transient_detected.emit("swell_start", 1.0)
		_cooldown_timer = 0.5

	_prev_magnitude = mag


func _analyze_climb() -> void:
	# CLIMB width expansion: could be mapped to spectral centroid or specific high-freq energy
	var mag_low: float = _analyzer.get_magnitude_for_frequency_range(20, 500).length()
	var mag_high: float = _analyzer.get_magnitude_for_frequency_range(5000, 20000).length()

	var width: float = 0.0
	if mag_low > 0.0:
		width = clampf(mag_high / mag_low, 0.0, 1.0)

	if DeterministicMath.absf(width - _climb_width) > 0.05:
		_climb_width = width
		feature_updated.emit("width", _climb_width)

	_prev_magnitude = (mag_low + mag_high) / 2.0
