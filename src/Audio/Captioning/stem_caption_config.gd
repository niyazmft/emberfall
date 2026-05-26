extends RefCounted

## StemCaptionConfig
## Per-stem root config types.
## Implementation of DON-223.

const SparseEventMarker = preload("res://src/Audio/Captioning/sparse_event_marker.gd")

var stem_id: String = ""
var cooldown_ms: int = 0
var markers: Dictionary = {} # event_id -> SparseEventMarker

func _init(p_data: Dictionary = {}) -> void:
	if p_data.is_empty():
		return

	stem_id = p_data.get("StemId", "")
	cooldown_ms = p_data.get("CooldownMs", 0)

	var markers_data = p_data.get("Markers", [])
	for m_data in markers_data:
		var marker = SparseEventMarker.new(m_data)
		markers[marker.event_id] = marker
