class_name BaseEnemy
extends Node2D
## Enemy scene root with configurable AI behavior

@export var archetype_id: String = ""
@export var elite_type: String = ""
@export var behavior_override: String = ""
@export var entity: Entity
@export var ai_controller: Node  ## Will integrate with behavior tree
@export var visual_proxy: EntityVisualProxy
@export var debug_color: Color = Color.WHITE
@export var visual_scale: float = 1.0

var _grid_system: _GridSystem
var _combat_system: Node  ## Placeholder for future combat system
var _apparition_renderer: ApparitionRenderer = null


func _ready() -> void:
	add_to_group("enemies")
	if _grid_system == null:
		_grid_system = AutoloadHelper.grid_system()

	_apparition_renderer = get_node_or_null("ApparitionRenderer") as ApparitionRenderer

	# In Godot, properties are set BEFORE _ready().
	# So archetype_id should already be what was set in _init() or in the inspector.
	_setup_entity()
	_setup_ai()
	_setup_visual_proxy()


func _process(_delta: float) -> void:
	# Sync apparition position to the visual proxy's position (which interpolates)
	if _apparition_renderer != null:
		if visual_proxy:
			_apparition_renderer.sync_to_owner(visual_proxy.global_position)
		else:
			_apparition_renderer.sync_to_owner(global_position)


func _setup_entity() -> void:
	# Initialize entity if not set
	if entity == null:
		entity = Entity.new("Enemy", 0, 0, 30, 8, 4)
		entity.is_player = false

	_load_stats_from_config()


func _load_stats_from_config() -> void:
	if archetype_id.is_empty():
		# Try to determine archetype from class name or other hints if empty
		# Use polymorphic check if available, otherwise default to "grunt"
		if has_method("get_archetype_id"):
			archetype_id = call("get_archetype_id")
		else:
			# Fallback to grunt if still empty
			archetype_id = "grunt"

	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if config_loader == null:
		return

	var enemies_config: Variant = config_loader.getValue("enemies")
	if enemies_config is Dictionary and enemies_config.has(archetype_id):
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

		entity.archetype_id = archetype_id
		entity.hp_max = int(data.get("hp_max", 30))
		entity.off = int(data.get("off", 8))
		entity.def_ = int(data.get("def_", 4))
		entity.spd = int(data.get("spd", 4))

		_apply_elite_modifiers()
		entity.hp = entity.hp_max
	else:
		push_warning(
			(
				"BaseEnemy: Archetype ID '%s' not found in config for node '%s'. Using defaults."
				% [archetype_id, name]
			)
		)


func _apply_elite_modifiers() -> void:
	if elite_type.is_empty():
		return

	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	if config_loader == null:
		return

	var elite_config: Dictionary = config_loader.getValue("elite_modifiers", "", {})
	if elite_config.has(elite_type):
		var mods: Dictionary = elite_config[elite_type]
		var prefix: String = mods.get("name_prefix", "")
		if not prefix.is_empty():
			entity.entity_name = prefix + " " + entity.entity_name

		entity.hp_max = DeterministicMath.damage_floor(
			float(entity.hp_max) * float(mods.get("hp_mult", 1.0))
		)
		entity.off = DeterministicMath.damage_floor(
			float(entity.off) * float(mods.get("off_mult", 1.0))
		)
		entity.def_ = DeterministicMath.damage_floor(
			float(entity.def_) * float(mods.get("def_mult", 1.0))
		)
		entity.spd = DeterministicMath.damage_floor(
			float(entity.spd) * float(mods.get("spd_mult", 1.0))
		)


func _setup_ai() -> void:
	# If archetype defines behavior, try to apply it
	var config_loader: _ConfigLoader = AutoloadHelper.config_loader()
	var behavior_str: String = ""
	if config_loader:
		var enemies_config: Variant = config_loader.getValue("enemies")
		if enemies_config is Dictionary and enemies_config.has(archetype_id):
			behavior_str = enemies_config[archetype_id].get("ai_behavior", "")

	if ai_controller and ai_controller is EnemyAIController:
		var controller: EnemyAIController = ai_controller as EnemyAIController

		# Apply behavior override if present
		var final_behavior: String = behavior_str
		if not behavior_override.is_empty():
			final_behavior = behavior_override

		match final_behavior.to_upper():
			"GRUNT":
				controller.behavior = EnemyAIController.BehaviorType.GRUNT
			"ARCHER":
				# If we have a specific ArcherAI node, it will handle itself.
				# Otherwise we set the behavior on the generic controller.
				controller.behavior = EnemyAIController.BehaviorType.ARCHER
			"TANK":
				controller.behavior = EnemyAIController.BehaviorType.TANK
			"":
				controller.behavior = EnemyAIController.BehaviorType.GRUNT
			_:
				controller.behavior = EnemyAIController.BehaviorType.BOSS
				controller.boss_behavior_name = final_behavior

	# Handle specific AI scripts if they exist as nodes
	if behavior_str.to_upper() == "ARCHER" and not ai_controller is ArcherAI:
		# If the current ai_controller is not ArcherAI but the behavior is ARCHER,
		# we might want to swap it or ensure it's handled.
		# For now, SimpleAI handles basic Archer behavior too.
		pass


func _setup_visual_proxy() -> void:
	# Connect visual_proxy to entity
	if visual_proxy and entity:
		visual_proxy.entity = entity
		visual_proxy.modulate = debug_color
		visual_proxy.scale = Vector2(visual_scale, visual_scale)


## Combat API
func take_turn() -> void:
	## Called by combat system when it's this enemy's turn
	if ai_controller is EnemyAIController:
		var action: Dictionary = (ai_controller as EnemyAIController).decide_action(entity)
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

	var target_entity: Entity = null
	if target_node is BaseEnemy:
		target_entity = (target_node as BaseEnemy).entity
	elif target_node is Keeper:
		target_entity = (target_node as Keeper).entity

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
	if target_node is BaseEnemy:
		(target_node as BaseEnemy).trigger_damage_effect()
	elif target_node is Keeper:
		(target_node as Keeper).trigger_damage_effect()

	# Deduct AP
	entity.ap = DeterministicMath.clampi(entity.ap - cost, 0, GameConstants.AP_MAX)


## Damage API
func trigger_damage_effect() -> void:
	if _apparition_renderer != null:
		_apparition_renderer.trigger_damage_effect()


func apply_damage(damage: int, attacker: Entity = null) -> void:
	## Apply damage through EntityLifecycle via AutoloadHelper
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.apply_damage(attacker, entity, damage)
	else:
		entity.apply_damage(damage)

	## Trigger visual effect
	trigger_damage_effect()


func alive() -> bool:
	return entity.alive() if entity else false
