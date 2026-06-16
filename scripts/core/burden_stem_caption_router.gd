class_name _BurdenStemCaptionRouter
extends Node

## BurdenStemCaptionRouter
## Core router with per-stem max-frequency cooldown and logical-event dispatch.
## Implementation of DON-223.

# ── Properties ────────────────────────────────────────────────────────────
var _configs: Dictionary = {}  # stem_id -> StemCaptionConfig
var _cooldowns: Dictionary = {}  # stem_id -> time_remaining_ms
var _presenter: Node = null  # Must implement present_caption(marker)

# ── Lifecycle ────────────────────────────────────────────────────────────────


func _ready() -> void:
	_load_config("res://data/captioning/burden_stems.json")


func _process(delta: float) -> void:
	for stem_id: String in _cooldowns.keys():
		_cooldowns[stem_id] = maxf(0.0, float(_cooldowns[stem_id]) - delta)


# ── Public API ─────────────────────────────────────────────────────────────


func set_presenter(p_presenter: Node) -> void:
	_presenter = p_presenter


func would_dispatch(stem_id: String, event_id: String) -> bool:
	if not _configs.has(stem_id):
		return false

	var config: RefCounted = _configs[stem_id] as RefCounted
	var markers: Dictionary = config.get("markers") as Dictionary
	if not markers.has(event_id):
		return false

	# Check cooldown
	if float(_cooldowns.get(stem_id, 0.0)) > 0.0:
		return false

	# Check MWT binding (logic: fire if current MWT >= marker.mwt_binding)
	var marker: RefCounted = markers[event_id] as RefCounted

	var mwt: int = 0
	var bm: Node = AutoloadHelper.burden_manager()
	if bm != null:
		mwt = int(bm.get("current_mwt_level"))

	if mwt < int(marker.get("mwt_binding")):
		return false

	return true


func dispatch_event(stem_id: String, event_id: String) -> void:
	if not would_dispatch(stem_id, event_id):
		return

	var config: RefCounted = _configs[stem_id] as RefCounted
	var markers: Dictionary = config.get("markers") as Dictionary
	var marker: RefCounted = markers[event_id] as RefCounted

	# Apply cooldown (converted to seconds)
	_cooldowns[stem_id] = float(config.get("cooldown_ms")) / 1000.0

	# Dispatch to presenter (lazily resolved if null or invalid)
	var presenter: Node = _presenter
	if not presenter or not is_instance_valid(presenter):
		var ml: MainLoop = Engine.get_main_loop()
		if ml is SceneTree:
			presenter = ml.root.find_child("SubtitleManager", true, false)
			_presenter = presenter

	if presenter and presenter.has_method("present_caption"):
		presenter.call("present_caption", marker)

	_print_debug("Dispatched event: %s/%s" % [stem_id, event_id])


func reset_cooldowns() -> void:
	_cooldowns.clear()


# ── Internal ────────────────────────────────────────────────────────────────


func _load_config(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("BurdenStemCaptionRouter: Config file not found at %s" % path)
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json_text: String = file.get_as_text()
	file.close()

	var json: Variant = JSON.parse_string(json_text)

	if json is Dictionary and (json as Dictionary).has("stems"):
		var stems_list: Array = (json as Dictionary)["stems"] as Array
		for stem_data: Variant in stems_list:
			if stem_data is Dictionary:
				var script: GDScript = load("res://scripts/core/stem_caption_config.gd") as GDScript
				var config: RefCounted = script.new(stem_data as Dictionary) as RefCounted
				_configs[str(config.get("stem_id"))] = config
	else:
		push_error("BurdenStemCaptionRouter: Invalid config format in %s" % path)


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenStemCaptionRouter: %s" % msg)
