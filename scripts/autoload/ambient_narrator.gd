extends Node
class_name _AmbientNarrator

## AmbientNarrator
## Manages environmental narrative triggers and elevation-based flavor text.
## Uses CaptionManager's AMBIENT channel for display.
## Architecture: Data-driven via ConfigLoader.


func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.connect(_on_room_entered)
	else:
		push_error("AmbientNarrator: EventBus not found")


func _on_room_entered(_room_index: int, _room_data: Dictionary) -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl == null:
		return

	# 1. Trigger generic room-entry triggers
	var triggers: Variant = cl.getValue("triggers")
	if triggers is Array:
		for trigger: Variant in triggers:
			if trigger is Dictionary and trigger.get("event_type") == "room_entered":
				var loc_key: String = trigger.get("localization_key", "")
				if not loc_key.is_empty():
					trigger_narrative(loc_key)

	# 2. Trigger initial elevation flavor
	var biome_id: String = _room_data.get("biome_id", "biome_1")
	# In Emberfall, player typically starts at a certain elevation,
	# but we'll assume elevation 0 for the initial flavor trigger or get it from player.
	trigger_elevation_flavor(biome_id, 0)


## Public API to trigger a narrative caption.
func trigger_narrative(loc_key: String) -> void:
	var cm: _CaptionManager = AutoloadHelper.caption_manager()
	if cm:
		# Using tr() to get localized text
		var text: String = tr(loc_key)
		cm.schedule(text, _CaptionManager.Channel.AMBIENT, 0.5, 3.0)
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
