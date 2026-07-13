class_name _BuildTracker
extends Node
## BuildTracker (FIX #599)
## Tracks player actions and combos during a run for end-of-run summary.
## Registered as autoload for cross-system access.

var blessing_id: String = ""
var blessing_tags: Array[String] = []
var total_kills: int = 0
var total_damage_dealt: int = 0
var total_damage_taken: int = 0
var rooms_cleared: int = 0
var turns_survived: int = 0
var moral_weight_final: int = 0
var _element_usage: Dictionary = {}  # element string -> count
var _combo_usage: Dictionary = {}  # combo string -> count
var _actions_taken: Dictionary = {}  # action type -> count


func set_blessing(blessing: BlessingSystem) -> void:
	if blessing == null:
		return
	blessing_id = blessing.current_blessing_id()
	blessing_tags = blessing.current_blessing_tags()


func record_kill() -> void:
	total_kills += 1


func record_damage_dealt(amount: int) -> void:
	total_damage_dealt += amount


func record_damage_taken(amount: int) -> void:
	total_damage_taken += amount


func record_room_cleared() -> void:
	rooms_cleared += 1


func record_turn() -> void:
	turns_survived += 1


func record_element_use(element: String) -> void:
	var key: String = element.to_lower()
	_element_usage[key] = int(_element_usage.get(key, 0)) + 1


func record_combo(combo_name: String) -> void:
	_combo_usage[combo_name] = int(_combo_usage.get(combo_name, 0)) + 1


func record_action(action_type: String) -> void:
	_actions_taken[action_type] = int(_actions_taken.get(action_type, 0)) + 1


func set_moral_weight(value: int) -> void:
	moral_weight_final = value


## Returns the top 3 elements used, sorted by count.
func top_elements() -> Array[String]:
	var sorted: Array = _element_usage.keys()
	sorted.sort_custom(
		func(a: String, b: String) -> bool:
			return int(_element_usage.get(a, 0)) > int(_element_usage.get(b, 0))
	)
	var result: Array[String] = []
	for i: int in range(mini(3, sorted.size())):
		result.append(sorted[i])
	return result


## Returns the top 3 combos used, sorted by count.
func top_combos() -> Array[String]:
	var sorted: Array = _combo_usage.keys()
	sorted.sort_custom(
		func(a: String, b: String) -> bool:
			return int(_combo_usage.get(a, 0)) > int(_combo_usage.get(b, 0))
	)
	var result: Array[String] = []
	for i: int in range(mini(3, sorted.size())):
		result.append(sorted[i])
	return result


## Returns a playstyle tag based on build choices.
func playstyle_tag() -> String:
	if total_kills == 0:
		return "Pacifist"
	if moral_weight_final >= 5:
		return "Burdened"
	if blessing_tags.has("pyromaniac"):
		return "Pyromaniac"
	if blessing_tags.has("tactician"):
		return "Tactician"
	if blessing_tags.has("glass_cannon"):
		return "Glass Cannon"
	if blessing_tags.has("zone_control"):
		return "Zone Controller"
	if blessing_tags.has("survivor"):
		return "Survivor"
	if blessing_tags.has("assassin"):
		return "Assassin"
	if total_damage_dealt > total_damage_taken * 3:
		return "Aggressor"
	if total_damage_taken > total_damage_dealt:
		return "Endurer"
	return "Tactician"


## Serializes build summary to Dictionary for display.
func to_summary() -> Dictionary:
	return {
		"blessing_id": blessing_id,
		"blessing_tags": blessing_tags.duplicate(),
		"top_elements": top_elements(),
		"top_combos": top_combos(),
		"playstyle": playstyle_tag(),
		"total_kills": total_kills,
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken,
		"rooms_cleared": rooms_cleared,
		"turns_survived": turns_survived,
		"moral_weight_final": moral_weight_final,
	}
