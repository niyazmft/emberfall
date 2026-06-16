class_name _StemCaptionConfig
extends RefCounted

## StemCaptionConfig
## Per-stem root config types.
## Implementation of DON-223.

var stem_id: String = ""
var cooldown_ms: int = 0
var markers: Dictionary = {}  # event_id -> SparseEventMarker


func _init(p_data: Dictionary = {}) -> void:
	if p_data.is_empty():
		return

	stem_id = str(p_data.get("StemId", ""))
	cooldown_ms = int(p_data.get("CooldownMs", 0))

	var markers_data: Array = p_data.get("Markers", []) as Array
	for m_data: Variant in markers_data:
		if m_data is Dictionary:
			var script: GDScript = load("res://scripts/core/sparse_event_marker.gd") as GDScript
			var marker: RefCounted = script.new(m_data as Dictionary) as RefCounted
			markers[str(marker.get("event_id"))] = marker
