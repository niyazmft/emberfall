class_name EnemyTank
extends BaseEnemy


func get_archetype_id() -> String:
	return "tank"


var taunt_radius: int = 3
var shield_block_cooldown: int = 3
var flanking_weights: Dictionary = {}


func _init() -> void:
	archetype_id = "tank"


func _load_stats_from_config() -> void:
	super._load_stats_from_config()

	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if config_loader == null:
		return

	var enemies_config: Dictionary = config_loader.getValue("enemies", "", {})
	if enemies_config.has(archetype_id):
		var data: Dictionary = enemies_config[archetype_id]
		taunt_radius = int(data.get("taunt_radius", 3))
		shield_block_cooldown = int(data.get("shield_block_cooldown", 3))
		flanking_weights = data.get("flanking_protection_weights", {}).duplicate()
