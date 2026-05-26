extends RefCounted

## SparseEventMarker
## Metadata record for a single sparse event.
## Implementation of DON-223.

var event_id: String = ""
var caption_category: String = ""
var priority: int = 0
var default_text: String = ""
var emotional_tier: int = 0
var source_type: String = ""
var duration_ms: int = 0
var mwt_binding: int = 0

func _init(p_data: Dictionary = {}) -> void:
	if p_data.is_empty():
		return

	event_id = p_data.get("EventId", "")
	caption_category = p_data.get("CaptionCategory", "")
	priority = p_data.get("Priority", 0)
	default_text = p_data.get("DefaultText", "")
	emotional_tier = p_data.get("EmotionalTier", 0)
	source_type = p_data.get("SourceType", "")
	duration_ms = p_data.get("DurationMs", 0)
	mwt_binding = p_data.get("MWTBinding", 0)
