class_name BurdenKillRecord
extends RefCounted

## BurdenKillRecord
## Data record for a sentient enemy kill.

var enemy_id: String
var display_name: String
var timestamp_ms: int


func _init(p_id: String, p_name: String, p_time: int) -> void:
	enemy_id = p_id
	display_name = p_name
	timestamp_ms = p_time
