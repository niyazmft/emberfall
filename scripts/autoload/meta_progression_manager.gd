extends Node
class_name _MetaProgressionManager

## Autoload: MetaProgressionManager
## Manages Echo Shards (meta-currency) and persistent unlocks.

signal currency_changed(new_amount: int)
signal unlock_purchased(unlock_id: String)

var _echo_shards: int = 0
var _meta_unlocks: Array[String] = []
var _unlock_defs: Dictionary = {}


func _ready() -> void:
	_load_unlock_definitions()
	_connect_to_save_manager()


func _load_unlock_definitions() -> void:
	var configLoader: _ConfigLoader = AutoloadHelper.config_loader()
	if configLoader:
		var data: Variant = configLoader.getValue("unlocks")
		if data is Dictionary:
			_unlock_defs = data


func _connect_to_save_manager() -> void:
	var sm: _SaveManager = AutoloadHelper.save_manager()
	if sm:
		sm.load_completed.connect(_on_save_loaded)


func _on_save_loaded(data: Dictionary) -> void:
	if data.has("player_profile"):
		var profile: Dictionary = data["player_profile"]
		if profile.has("echo_shards"):
			_echo_shards = int(profile["echo_shards"])
		if profile.has("meta_unlocks"):
			var unlocks: Array = profile["meta_unlocks"]
			_meta_unlocks.clear()
			for u: Variant in unlocks:
				_meta_unlocks.append(str(u))
	currency_changed.emit(_echo_shards)


## Returns the current amount of Echo Shards.
func get_echo_shards() -> int:
	return _echo_shards


## Adds Echo Shards.
func add_echo_shards(amount: int) -> void:
	_echo_shards += amount
	currency_changed.emit(_echo_shards)


## Returns true if an unlock has been purchased.
func is_unlocked(unlock_id: String) -> bool:
	return _meta_unlocks.has(unlock_id)


## Attempts to purchase an unlock.
func purchase_unlock(unlock_id: String) -> bool:
	if not _unlock_defs.has(unlock_id):
		return false
	if is_unlocked(unlock_id):
		return false

	var def: Dictionary = _unlock_defs[unlock_id]
	var cost: int = int(def.get("cost", 0))

	if _echo_shards >= cost:
		_echo_shards -= cost
		_meta_unlocks.append(unlock_id)
		currency_changed.emit(_echo_shards)
		unlock_purchased.emit(unlock_id)
		return true
	return false


## Returns a bonus for a specific stat based on meta-unlocks.
func get_stat_bonus(effect_id: String) -> float:
	var total_bonus: float = 0.0
	for unlock_id: String in _meta_unlocks:
		var def: Dictionary = _unlock_defs.get(unlock_id, {})
		if def.get("effect_id") == effect_id:
			total_bonus += float(def.get("effect_value", 0.0))
	return total_bonus


## Serialization for SaveManager.
func get_save_data() -> Dictionary:
	return {"echo_shards": _echo_shards, "meta_unlocks": _meta_unlocks}
