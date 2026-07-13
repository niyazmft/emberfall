class_name _BlessingSystem
extends Node
## BlessingSystem (FIX #599)
## Manages run Blessings: seed-based generation, selection, and modifier queries.
## Registered as autoload for cross-system access.

## Emitted when a blessing is selected.
signal blessing_selected(blessing_id: String)

var _blessing_pool: Array[Dictionary] = []
var _selected_blessing: Dictionary = {}
var _active_modifiers: Dictionary = {}
var _run_seed: int = 0


## Generate 3 blessings deterministically from the run seed.
func generate_blessings(run_seed: int) -> Array[Dictionary]:
	_run_seed = run_seed
	var all: Array = _load_all_blessings()
	if all.is_empty():
		return []

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SeedGovernance.hash_int(run_seed, "BLESSINGS")

	# Shuffle using deterministic RNG.
	var shuffled: Array = all.duplicate()
	for i: int in range(shuffled.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp

	var result: Array[Dictionary] = []
	for i: int in range(mini(3, shuffled.size())):
		if shuffled[i] is Dictionary:
			result.append(shuffled[i] as Dictionary)
	_blessing_pool = result
	return result


## Select a blessing by index from the generated pool.
func select_blessing(index: int) -> void:
	if index < 0 or index >= _blessing_pool.size():
		push_warning("BlessingSystem: invalid selection index %d" % index)
		return
	_selected_blessing = _blessing_pool[index]
	_active_modifiers = _selected_blessing.get("modifiers", {}) as Dictionary
	blessing_selected.emit(_selected_blessing.get("id", ""))


## Clear selection (called at end of run).
func clear() -> void:
	_selected_blessing = {}
	_active_modifiers = {}
	_blessing_pool.clear()


## Returns the currently selected blessing ID, or empty string if none.
func current_blessing_id() -> String:
	return _selected_blessing.get("id", "")


## Returns the currently selected blessing name key.
func current_blessing_name() -> String:
	return _selected_blessing.get("name_key", "")


## Returns the currently selected blessing tags.
func current_blessing_tags() -> Array[String]:
	var tags: Array = _selected_blessing.get("tags", []) as Array
	var result: Array[String] = []
	for t: Variant in tags:
		if t is String:
			result.append(t as String)
	return result


## ── Modifier Queries ──────────────────────────────────────────────────


## Get a modifier value. Returns `fallback` if the modifier is not present.
func get_modifier(key: String, fallback: float = 0.0) -> float:
	return float(_active_modifiers.get(key, fallback))


## Returns true if the selected blessing has any modifier matching the prefix.
func has_modifier_prefix(prefix: String) -> bool:
	for k: String in _active_modifiers.keys():
		if k.begins_with(prefix):
			return true
	return false


## ── Combat-Affecting Modifiers (convenience wrappers) ────────────────


func damage_multiplier(element: String = "") -> float:
	var base: float = 1.0
	if not element.is_empty():
		base += get_modifier("damage_%s" % element, 0.0)
	base += get_modifier("damage_all", 0.0)
	return base


func ap_cost_modifier(action_type: String = "") -> int:
	var mod: int = 0
	if not action_type.is_empty():
		mod += int(get_modifier("ap_cost_%s" % action_type, 0.0))
	mod += int(get_modifier("ap_cost_all", 0.0))
	return mod


func hp_max_bonus() -> int:
	return int(get_modifier("hp_max_bonus", 0.0))


func def_bonus() -> int:
	return int(get_modifier("def_bonus", 0.0))


func spd_bonus() -> int:
	return int(get_modifier("spd_bonus", 0.0))


func combo_damage_bonus() -> float:
	return get_modifier("combo_damage_bonus", 0.0)


func desperation_multiplier() -> float:
	return get_modifier("desperation_multiplier", 0.0)


## ── Private ──────────────────────────────────────────────────────────


func _load_all_blessings() -> Array:
	var cfg: _ConfigLoader = AutoloadHelper.config_loader()
	if cfg == null:
		return []
	var data: Dictionary = cfg.getValue("blessings", "", {})
	var pool: Array = data.get("pool", []) as Array
	# Validate entries are dictionaries.
	var result: Array = []
	for item: Variant in pool:
		if item is Dictionary:
			result.append(item)
	return result
