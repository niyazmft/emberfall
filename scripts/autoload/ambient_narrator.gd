class_name _AmbientNarrator
extends Node

## AmbientNarrator
## Manages environmental narrative triggers and elevation-based flavor text.
## Uses CaptionManager's AMBIENT channel for display.
## Architecture: Data-driven via ConfigLoader.

var _visited_biomes: Dictionary = {}


func _ready() -> void:
	_connect_signals()


func _exit_tree() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		if eb.room_entered.is_connected(_on_room_entered):
			eb.room_entered.disconnect(_on_room_entered)
		if eb.run_started.is_connected(_on_run_started):
			eb.run_started.disconnect(_on_run_started)
		if eb.run_ended.is_connected(_on_run_ended):
			eb.run_ended.disconnect(_on_run_ended)
		if eb.spare_or_execute.is_connected(_on_spare_or_execute):
			eb.spare_or_execute.disconnect(_on_spare_or_execute)
		if eb.biome_echo_triggered.is_connected(_on_biome_echo_triggered):
			eb.biome_echo_triggered.disconnect(_on_biome_echo_triggered)


func _connect_signals() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.connect(_on_room_entered)
		eb.run_started.connect(_on_run_started)
		eb.run_ended.connect(_on_run_ended)
		eb.spare_or_execute.connect(_on_spare_or_execute)
		eb.biome_echo_triggered.connect(_on_biome_echo_triggered)
	else:
		push_error("AmbientNarrator: EventBus not found")


func _on_room_entered(room_index: int, room_data: Dictionary) -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	var biome_index: int = int(room_data.get("biome", 0))
	var biome_id: String = "biome%d" % (biome_index + 1)

	# 1. Trigger biome entry narrative on first visit
	if not _visited_biomes.has(biome_index):
		_visited_biomes[biome_index] = true
		var biome_entry: Variant = cl.getValue("biome_entry")
		if biome_entry is Dictionary:
			var loc_key: String = biome_entry.get(str(biome_index), "")
			if not loc_key.is_empty():
				trigger_narrative(loc_key)

	# 2. Trigger boss intro for boss rooms
	var room_id: String = str(room_data.get("id", ""))
	if room_id.begins_with("boss_"):
		_trigger_boss_intro(room_id, room_index)

	# 3. Trigger generic room-entry triggers
	var triggers: Variant = cl.getValue("triggers")
	if triggers is Array:
		for trigger: Variant in triggers:
			if trigger is Dictionary and trigger.get("event_type") == "room_entered":
				var loc_key: String = trigger.get("localization_key", "")
				if not loc_key.is_empty():
					trigger_narrative(loc_key)

	# 4. Trigger initial elevation flavor
	# In Emberfall, player typically starts at a certain elevation,
	# but we'll assume elevation 0 for the initial flavor trigger or get it from player.
	trigger_elevation_flavor(biome_id, 0)

	# 5. Trigger biome echo with a slight delay
	_trigger_random_biome_echo(biome_id, room_index, 1.5)


func _on_run_started(_seed: int) -> void:
	_visited_biomes.clear()
	_trigger_event_narrative("run_started")


func _on_run_ended(result: StringName, _context: Dictionary) -> void:
	if result == &"TRIUMPH":
		_trigger_event_narrative("run_ended_victory")
	else:
		_trigger_event_narrative("run_ended_defeat")


func _on_spare_or_execute(_entity: Entity, was_spared: bool) -> void:
	if was_spared:
		_trigger_event_narrative("spare")
	else:
		_trigger_event_narrative("execute")


func _on_biome_echo_triggered(biome_index: int) -> void:
	var biome_id := "biome%d" % (biome_index + 1)
	# Use a static index for biome-level threshold echoes, or random.
	# We'll use 0 as the "threshold" echo.
	_trigger_biome_echo(biome_id, 0)


func _trigger_boss_intro(room_id: String, room_index: int) -> void:
	## Select a deterministic boss intro variant based on room id and index.
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	var boss_intros: Variant = cl.getValue("boss_intros")
	if boss_intros is Dictionary and boss_intros.has(room_id):
		var variants: Array = boss_intros[room_id] as Array
		if not variants.is_empty():
			var idx: int = room_index % variants.size()
			trigger_narrative(variants[idx])


func _trigger_event_narrative(event_type: String) -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	var triggers: Variant = cl.getValue("triggers")
	if triggers is Array:
		for trigger: Variant in triggers:
			if trigger is Dictionary and trigger.get("event_type") == event_type:
				var loc_key: String = trigger.get("localization_key", "")
				if not loc_key.is_empty():
					trigger_narrative(loc_key)
				return


func _trigger_random_biome_echo(biome_id: String, room_index: int, offset: float = 0.0) -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	var biome_echoes: Variant = cl.getValue("biome_echoes")
	if biome_echoes is Dictionary and biome_echoes.has(biome_id):
		var echoes: Array = biome_echoes[biome_id]
		if not echoes.is_empty():
			# Deterministic variety based on room index
			var idx: int = room_index % echoes.size()
			trigger_narrative(echoes[idx], offset)


func _trigger_biome_echo(biome_id: String, echo_index: int) -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	var biome_echoes: Variant = cl.getValue("biome_echoes")
	if biome_echoes is Dictionary and biome_echoes.has(biome_id):
		var echoes: Array = biome_echoes[biome_id]
		if echoes.size() > echo_index:
			trigger_narrative(echoes[echo_index])


## Public API to trigger a narrative caption.
func trigger_narrative(loc_key: String, offset_sec: float = 0.0) -> void:
	var cm := AutoloadHelper.caption_manager()
	if cm:
		# Using tr() to get localized text
		var text: String = tr(loc_key)
		cm.schedule(text, 2, offset_sec, 3.0)  # Channel.AMBIENT = 2
	else:
		push_error("AmbientNarrator: CaptionManager not found")


## Trigger elevation flavor text based on biome and elevation level.
func trigger_elevation_flavor(biome_id: String, elevation: int) -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	var biomes: Variant = cl.getValue("biomes")
	if biomes is Dictionary and biomes.has(biome_id):
		var biome_data: Dictionary = biomes[biome_id]
		var elevation_flavor: Dictionary = biome_data.get("elevation_flavor", {})
		var loc_key: String = elevation_flavor.get(str(elevation), "")
		if not loc_key.is_empty():
			trigger_narrative(loc_key)
