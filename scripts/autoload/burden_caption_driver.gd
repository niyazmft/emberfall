extends Node

## _BurdenCaptionDriver
## Listens to AudioMiddleware and triggers captions via CaptionManager.
## Implements cooldown guards and event mapping.

class_name _BurdenCaptionDriver

# ── Constants ─────────────────────────────────────────────────────────────
const COOLDOWN_DEFAULT: float = 1.0
const COOLDOWN_CLANG: float = 0.5
const MIN_INTENSITY: float = 0.2

# ── Properties ────────────────────────────────────────────────────────────
var _cooldowns: Dictionary = {}
var _expired_keys: Array[String] = []

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _ready() -> void:
	_connect_middleware()
	_print_debug("BurdenCaptionDriver ready")


func _exit_tree() -> void:
	var am: _AudioMiddleware = AutoloadHelper.get_autoload("AudioMiddleware") as _AudioMiddleware
	if am != null and am.is_connected("stem_event_detected", _on_stem_event):
		am.stem_event_detected.disconnect(_on_stem_event)


func _process(delta: float) -> void:
	if _cooldowns.is_empty():
		return

	# ⚡ Bolt: Iterate over dictionary directly to avoid Array allocation every frame.
	_expired_keys.clear()
	for key: String in _cooldowns:
		_cooldowns[key] -= delta
		if _cooldowns[key] <= 0.0:
			_expired_keys.append(key)

	for key: String in _expired_keys:
		_cooldowns.erase(key)


# ── Internal ────────────────────────────────────────────────────────────────


func _connect_middleware() -> void:
	var am: _AudioMiddleware = AutoloadHelper.get_autoload("AudioMiddleware") as _AudioMiddleware
	if am != null and am.has_signal("stem_event_detected"):
		am.stem_event_detected.connect(_on_stem_event)


func _on_stem_event(stem_id: String, event_type: String, intensity: float) -> void:
	if intensity < MIN_INTENSITY:
		return

	var cooldown_key: String = "%s_%s" % [stem_id, event_type]
	if _cooldowns.has(cooldown_key):
		return

	_map_and_trigger_caption(stem_id, event_type, intensity)

	# Apply cooldown
	var cooldown: float = COOLDOWN_DEFAULT
	if event_type == "clang":
		cooldown = COOLDOWN_CLANG
	_cooldowns[cooldown_key] = cooldown


func _map_and_trigger_caption(stem_id: String, event_type: String, intensity: float) -> void:
	var caption_text: String = ""
	var loc_key: String = ""
	var duration: float = 1.0

	match stem_id:
		"BD-BASS":
			if event_type == "impact":
				caption_text = "[Deep impact]"
				loc_key = "BE_CAP_BASS_IMPACT"
				duration = 1.5
		"BD-MECH":
			if event_type == "clang":
				caption_text = "[Mechanical clang]"
				loc_key = "BE_CAP_MECH_CLANG"
				duration = 0.8
		"BD-STRESS":
			if event_type == "swell_start" or event_type == "high_stress":
				caption_text = "[Tension rising]"
				loc_key = "BE_CAP_STRESS_SWELL"
				duration = 2.0
		"BD-CLIMB":
			if event_type == "width_change":
				if intensity > 0.7:
					caption_text = "[The walls widen]"
					loc_key = "BE_CAP_CLIMB_EXPAND"
				elif intensity < 0.3:
					caption_text = "[Everything converges]"
					loc_key = "BE_CAP_CLIMB_CONVERGE"
				duration = 2.0

	if not caption_text.is_empty():
		var cm: Node = AutoloadHelper.get_autoload("CaptionManager")
		if cm != null and cm.has_method("schedule"):
			# Channel.BURDEN = 1
			# CaptionCurve.LINEAR = 1
			cm.call("schedule", caption_text, 1, 0.0, duration, 1, loc_key)
			_print_debug("Triggered caption: %s (intensity=%.2f)" % [caption_text, intensity])

		# Also report to CaptionManager for screen readers/internal tracking
		if cm != null and cm.has_method("report_stem_transient"):
			cm.call("report_stem_transient", stem_id, event_type, intensity)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenCaptionDriver: %s" % msg)
