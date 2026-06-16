extends Node
class_name _LevelUpManager

## Autoload: LevelUpManager
## Orchestrates XP awards and player leveling based on progression.json and xp_economy.json.

signal experience_gained(entity: Entity, amount: int, reason: String)
signal level_up_achieved(entity: Entity, new_level: int)

var _progression_config: Dictionary = {}
var _xp_economy_config: Dictionary = {}


func _ready() -> void:
	_load_configs()
	_connect_signals()


func _load_configs() -> void:
	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if config_loader:
		_progression_config = config_loader.getValue("progression", "", {})
		_xp_economy_config = config_loader.getValue("xp_economy", "", {})


func _connect_signals() -> void:
	var event_bus: _EventBus = AutoloadHelper.event_bus()
	if event_bus:
		event_bus.spare_or_execute.connect(_on_spare_or_execute)
		event_bus.biome_echo_triggered.connect(_on_biome_echo_triggered)


func _exit_tree() -> void:
	var event_bus: _EventBus = AutoloadHelper.event_bus()
	if event_bus:
		if event_bus.spare_or_execute.is_connected(_on_spare_or_execute):
			event_bus.spare_or_execute.disconnect(_on_spare_or_execute)
		if event_bus.biome_echo_triggered.is_connected(_on_biome_echo_triggered):
			event_bus.biome_echo_triggered.disconnect(_on_biome_echo_triggered)


func grant_experience(entity: Entity, amount: int, reason: String = "") -> void:
	if amount <= 0:
		return

	var old_xp: int = entity.experience
	entity.experience += amount
	experience_gained.emit(entity, amount, reason)

	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		if eb.has_signal("experience_gained"):
			eb.experience_gained.emit(entity, amount, reason)

	_check_level_up(entity)


func _check_level_up(entity: Entity) -> void:
	var thresholds: Array = _progression_config.get("level_thresholds", [])
	if thresholds.is_empty():
		return

	var current_level: int = entity.level
	var next_level_idx: int = current_level - 1  # Level 1 is index -1, Level 2 is index 0

	while (
		next_level_idx < thresholds.size()
		and entity.experience >= int(thresholds[next_level_idx])
		and current_level < entity.get_effective_max_level()
	):
		current_level += 1
		next_level_idx = current_level - 1
		_apply_level_up(entity, current_level)


func _apply_level_up(entity: Entity, new_level: int) -> void:
	var old_level: int = entity.level
	entity.level = new_level

	var growth_data: Dictionary = _progression_config.get("stat_growth", {})
	var level_key: String = str(new_level)

	if growth_data.has(level_key):
		var stats: Dictionary = growth_data[level_key]
		entity.hp_max += int(stats.get("hp_max", 0))
		entity.hp = entity.hp_max  # Full heal on level up
		entity.off += int(stats.get("off", 0))
		entity.def_ += int(stats.get("def", 0))
		entity.spd += int(stats.get("spd", 0))

	level_up_achieved.emit(entity, new_level)
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.level_up_achieved.emit(entity, new_level)


func _on_spare_or_execute(entity: Entity, was_spared: bool) -> void:
	# entity here is the enemy
	var archetype: String = entity.archetype_id
	var enemy_xp_map: Dictionary = _xp_economy_config.get("enemy_xp", {})
	var base_xp: int = int(enemy_xp_map.get(archetype, 10))

	var player: Entity = _get_player_entity()
	if not player:
		return

	var final_xp: int = base_xp
	var formula_key: String = "spare_xp_formula" if was_spared else "execute_xp_formula"
	var hooks: Dictionary = _xp_economy_config.get("hooks", {})

	if hooks.has(formula_key):
		final_xp = _evaluate_formula(
			hooks[formula_key],
			{
				"base_xp": base_xp,
				"spare_bonus_multiplier": _xp_economy_config.get("spare_bonus_multiplier", 1.5)
			}
		)
	else:
		if was_spared:
			final_xp = DeterministicMath.floori(
				base_xp * _xp_economy_config.get("spare_bonus_multiplier", 1.5)
			)

	grant_experience(player, final_xp, "combat_resolution")


func _on_biome_echo_triggered(_biome_index: int) -> void:
	var player: Entity = _get_player_entity()
	if player:
		var bonus: int = int(_xp_economy_config.get("biome_clear_bonus", 100))
		grant_experience(player, bonus, "biome_clear")


func _evaluate_formula(formula: String, context: Dictionary) -> int:
	if not _is_formula_safe(formula, context.keys()):
		push_error("LevelUpManager: Formula failed safety check: " + formula)
		return int(context.get("base_xp", 0))

	var expr := Expression.new()
	var error := expr.parse(formula, context.keys())
	if error != OK:
		push_error("LevelUpManager: Formula parse error: " + expr.get_error_text())
		return int(context.get("base_xp", 0))

	# Use const_calls_only = true for extra safety
	var result: Variant = expr.execute(context.values(), null, true, true)
	if expr.has_execute_failed():
		push_error("LevelUpManager: Formula execution failed: " + expr.get_error_text())
		return int(context.get("base_xp", 0))

	return DeterministicMath.floori(float(result))


func _is_formula_safe(formula: String, allowed_variables: Array) -> bool:
	# 1. Check for unauthorized characters
	# Allowed: a-z, A-Z, 0-9, _, +, -, *, /, %, (, ), ., space
	var regex_chars := RegEx.new()
	regex_chars.compile("^[a-zA-Z0-9_\\+\\-\\*\\/\\%\\(\\)\\.\\s]*$")
	if not regex_chars.search(formula):
		return false

	# 2. Check identifiers
	# Identifiers start with a letter or underscore and contain letters, numbers, or underscores.
	var regex_id := RegEx.new()
	regex_id.compile("[a-zA-Z_][a-zA-Z0-9_]*")
	var matches: Array[RegExMatch] = regex_id.search_all(formula)
	for m: RegExMatch in matches:
		var identifier: String = m.get_string()
		if not identifier in allowed_variables:
			# Also allow common boolean/null literals if they somehow appear
			if identifier in ["true", "false", "null"]:
				continue
			return false

	return true


func _get_player_entity() -> Entity:
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		return lifecycle.player_entity
	return null
