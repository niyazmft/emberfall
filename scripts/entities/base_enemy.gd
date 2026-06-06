class_name BaseEnemy
extends Node2D
## Enemy scene root with configurable AI behavior

@export var archetype_id: String = ""
@export var entity: Entity
@export var ai_controller: Node  ## Will integrate with behavior tree
@export var visual_proxy: EntityVisualProxy
@export var debug_color: Color = Color.WHITE
@export var visual_scale: float = 1.0

var _grid_system: _GridSystem
var _combat_system: Node  ## Placeholder for future combat system


func _ready() -> void:
	add_to_group("enemies")
	if _grid_system == null:
		_grid_system = AutoloadHelper.grid_system()

	# In Godot, properties are set BEFORE _ready().
	# So archetype_id should already be what was set in _init() or in the inspector.
	_setup_entity()
	_setup_ai()
	_setup_visual_proxy()


func _process(_delta: float) -> void:
	# Sync apparition position to the visual proxy's position (which interpolates)
	if has_node("ApparitionRenderer"):
		var renderer: Node = get_node("ApparitionRenderer")
		if renderer.has_method("sync_to_owner"):
			if visual_proxy:
				renderer.call("sync_to_owner", visual_proxy.global_position)
			else:
				renderer.call("sync_to_owner", global_position)


func _setup_entity() -> void:
	# Initialize entity if not set
	if entity == null:
		entity = Entity.new("Enemy", 0, 0, 30, 8, 4)
		entity.is_player = false

	_load_stats_from_config()


func _load_stats_from_config() -> void:
	if archetype_id.is_empty():
		# Try to determine archetype from class name or other hints if empty
		if self is EnemyGrunt:
			archetype_id = "grunt"
		elif self is EnemyArcher:
			archetype_id = "archer"
		elif self is EnemyTank:
			archetype_id = "tank"
		else:
			# Fallback to grunt if still empty
			archetype_id = "grunt"

	# print("BaseEnemy: Loading stats for ", archetype_id)
	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if config_loader == null:
		return

	var enemies_config: Dictionary = config_loader.getValue("enemies", "", {})
	if enemies_config.has(archetype_id):
		var data: Dictionary = enemies_config[archetype_id]
		# Use data-driven name if present, otherwise fallback to existing name or capitalized ID
		if data.has("name"):
			entity.entity_name = data["name"]
		elif (
			entity.entity_name == "Unnamed"
			or entity.entity_name == "Enemy"
			or entity.entity_name == "Grunt"
		):
			# "Grunt" is the default in some constructors, but we want the specific archetype name
			entity.entity_name = archetype_id.capitalize()

		entity.hp_max = int(data.get("hp_max", 30))
		entity.hp = entity.hp_max
		entity.off = int(data.get("off", 8))
		entity.def_ = int(data.get("def_", 4))
		entity.spd = int(data.get("spd", 4))


func _setup_ai() -> void:
	# If archetype defines behavior, try to apply it
	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	var behavior_str: String = ""
	if config_loader:
		var enemies_config: Dictionary = config_loader.getValue("enemies", "", {})
		if enemies_config.has(archetype_id):
			behavior_str = enemies_config[archetype_id].get("ai_behavior", "")

	if ai_controller and ai_controller is EnemyAIController:
		var controller: EnemyAIController = ai_controller as EnemyAIController
		match behavior_str.to_upper():
			"GRUNT":
				controller.behavior = EnemyAIController.BehaviorType.GRUNT
			"ARCHER":
				controller.behavior = EnemyAIController.BehaviorType.ARCHER
			"TANK":
				controller.behavior = EnemyAIController.BehaviorType.TANK


func _setup_visual_proxy() -> void:
	# Connect visual_proxy to entity
	if visual_proxy and entity:
		visual_proxy.entity = entity
		visual_proxy.modulate = debug_color
		visual_proxy.scale = Vector2(visual_scale, visual_scale)


## Combat API
func take_turn() -> void:
	## Called by combat system when it's this enemy's turn
	if ai_controller and ai_controller.has_method("decide_action"):
		var action: Dictionary = ai_controller.call("decide_action", entity)
		_execute_action(action)


func _execute_action(action: Dictionary) -> void:
	## Execute decided action
	match action.get("type", ""):
		"move":
			_handle_move(action)
		"attack":
			_handle_attack(action)
		"wait":
			pass  # Do nothing


func _handle_move(action: Dictionary) -> void:
	var target_x: int = action.get("target_x", entity.x)
	var target_y: int = action.get("target_y", entity.y)

	# Calculate facing BEFORE updating position
	var dx: int = target_x - entity.x
	var dy: int = target_y - entity.y

	# Sprint 1: simple 1 AP per tile for cardinal, 2 for diagonal
	var cost: int = 1
	if dx != 0 and dy != 0:
		cost = 2

	# Reject if insufficient AP
	if entity.ap < cost:
		return

	if _grid_system and _grid_system.can_move(entity.x, entity.y, target_x, target_y):
		entity.set_grid_position(target_x, target_y)

		# Update facing if moved
		if dx != 0 or dy != 0:
			entity.set_facing(DeterministicMath.sgn(dx), DeterministicMath.sgn(dy))

		# Consume AP
		entity.ap = DeterministicMath.clampi(entity.ap - cost, 0, GameConstants.AP_MAX)


func _handle_attack(action: Dictionary) -> void:
	var target_node: Node2D = action.get("target") as Node2D
	if target_node == null:
		return

	var target_entity: Entity = target_node.get("entity") as Entity
	if target_entity == null:
		return

	# Consume AP
	var cost: int = CombatFormula.action_cost("attack_basic")
	if entity.ap < cost:
		return

	# Gather cover tiles for damage formula
	var cover_tiles: Array[Vector2i] = []
	if _grid_system:
		for tile: TacTileData in _grid_system.all_tiles():
			if tile.has_cover():
				cover_tiles.append(tile.coords)

	# Calculate damage
	var damage: int = CombatFormula.compute_damage_from_entities(entity, target_entity, cover_tiles)

	# Apply damage through lifecycle
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.apply_damage(entity, target_entity, damage)
	else:
		target_entity.apply_damage(damage)

	# Trigger visual recoil on target if it exposes the hook
	if target_node.has_method("trigger_damage_effect"):
		target_node.call("trigger_damage_effect")

	# Deduct AP
	entity.ap = DeterministicMath.clampi(entity.ap - cost, 0, GameConstants.AP_MAX)


## Damage API
func apply_damage(damage: int) -> void:
	## Apply damage through EntityLifecycle via AutoloadHelper
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.apply_damage(null, entity, damage)
	else:
		entity.apply_damage(damage)

	## Trigger visual effect
	## NOTE: ApparitionRenderer is not fully implemented yet. Use a safe fallback check.
	if has_node("ApparitionRenderer"):
		var renderer: Node = get_node("ApparitionRenderer")
		if renderer.has_method("trigger_damage_effect"):
			renderer.call("trigger_damage_effect")


func alive() -> bool:
	return entity.alive() if entity else false
