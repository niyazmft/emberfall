extends Node

## BurdenStemCaptionRouter
## Core router with per-stem max-frequency cooldown and logical-event dispatch.
## Implementation of DON-223.

const StemCaptionConfig = preload("res://src/Audio/Captioning/stem_caption_config.gd")
const SparseEventMarker = preload("res://src/Audio/Captioning/sparse_event_marker.gd")

# ── Properties ────────────────────────────────────────────────────────────
var _configs: Dictionary[String, StemCaptionConfig] = {}
var _cooldowns: Dictionary[String, float] = {}
var _presenter: Node = null # Must implement present_caption(marker)

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_config("res://data/captioning/burden_stems.json")

func _process(delta: float) -> void:
	for stem_id: String in _cooldowns:
		_cooldowns[stem_id] = maxf(0.0, _cooldowns[stem_id] - delta)

# ── Public API ─────────────────────────────────────────────────────────────

func set_presenter(p_presenter: Node) -> void:
	_presenter = p_presenter

func would_dispatch(stem_id: String, event_id: String) -> bool:
	if not _configs.has(stem_id):
		return false

	var config: StemCaptionConfig = _configs[stem_id] as StemCaptionConfig
	if not config.markers.has(event_id):
		return false

	# Check cooldown
	if _cooldowns.get(stem_id, 0.0) > 0.0:
		return false

	# Check MWT binding (logic: fire if current MWT >= marker.mwt_binding)
	var marker: SparseEventMarker = config.markers[event_id] as SparseEventMarker
	if BurdenManager and BurdenManager.current_mwt_level < marker.mwt_binding:
		return false

	return true

func dispatch_event(stem_id: String, event_id: String) -> void:
	if not would_dispatch(stem_id, event_id):
		return

	var config: StemCaptionConfig = _configs[stem_id] as StemCaptionConfig
	var marker: SparseEventMarker = config.markers[event_id] as SparseEventMarker

	# Apply cooldown (converted to seconds)
	_cooldowns[stem_id] = config.cooldown_ms / 1000.0

	# Dispatch to presenter (lazily resolved if null or invalid)
	var presenter: Node = _presenter
	if not presenter or not is_instance_valid(presenter):
		presenter = get_tree().root.find_child("SubtitleManager", true, false)
		_presenter = presenter

	if presenter and presenter.has_method("present_caption"):
		presenter.present_caption(marker)

	_print_debug("Dispatched event: %s/%s" % [stem_id, event_id])

func reset_cooldowns() -> void:
	_cooldowns.clear()

# ── Internal ────────────────────────────────────────────────────────────────

func _load_config(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("BurdenStemCaptionRouter: Config file not found at %s" % path)
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var json_text: String = file.get_as_text()
	var json: Variant = JSON.parse_string(json_text)

	if json is Dictionary and json.has("stems"):
		for stem_data: Dictionary in json["stems"]:
			var config := StemCaptionConfig.new(stem_data)
			_configs[config.stem_id] = config
	else:
		push_error("BurdenStemCaptionRouter: Invalid config format in %s" % path)

func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenStemCaptionRouter: %s" % msg)
