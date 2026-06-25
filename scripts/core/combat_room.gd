class_name CombatRoom
extends Node2D
## The root scene for all tactical gameplay.
## Handles the core visual architecture defined in AGENTS.md:
##   - GridRenderer: Isometric floor
##   - EntityContainer (YSort): Depth-sorted game entities
##   - UIOverlay: CanvasLayer for HUD and menus

const VICTORY_MODAL_SCENE_PATH: String = "res://scenes/ui/victory_modal.tscn"
const DEFEAT_MODAL_SCENE_PATH: String = "res://scenes/ui/defeat_modal.tscn"
const TURN_BANNER_SCENE_PATH: String = "res://scenes/ui/turn_banner.tscn"

@export var demo_mode: bool = false  # Load curated demo room when no RunManager present

var _grid_system: _GridSystem
var _player: Node2D  # Type will be Keeper
var _enemies_node: Node2D
var _combat_input: CombatInput
var _turn_manager: TurnManager
var _room_kills: int = 0
var _current_room_data: Dictionary = {}
var _boss_entity: Entity = null
var _reinforcements_spawned: bool = false

@onready var grid_renderer: GridRenderer = $GridRenderer
@onready var entity_container: Node2D = $EntityContainer
@onready var floating_text_container: Node2D = $EntityContainer/FloatingTextContainer
@onready var ui_overlay: CanvasLayer = $UIOverlay
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_grid_system = AutoloadHelper.grid_system()

	var run_manager := AutoloadHelper.run_manager()
	if run_manager:
		if not run_manager.room_entered.is_connected(_on_room_entered):
			run_manager.room_entered.connect(_on_room_entered)
		# If we are already in a room, trigger it manually
		if run_manager.current_state == _RunManager.RunState.ROOM:
			var room_data: Dictionary = run_manager.get_current_room_data()
			var sm: _SaveManager = AutoloadHelper.save_manager()
			var is_first_play: bool = sm != null and not sm.has_save()
			if run_manager.room_index == 0 and is_first_play:
				room_data = _load_tutorial_room_data()
			_on_room_entered(run_manager.room_index, room_data)
	elif demo_mode:
		_load_demo_room()

	var eb := AutoloadHelper.event_bus()
	if eb:
		if not eb.entity_state_changed.is_connected(_on_entity_state_changed):
			eb.entity_state_changed.connect(_on_entity_state_changed)

	_setup_camera()


func _exit_tree() -> void:
	var run_manager := AutoloadHelper.run_manager()
	if run_manager and run_manager.room_entered.is_connected(_on_room_entered):
		run_manager.room_entered.disconnect(_on_room_entered)

	var eb := AutoloadHelper.event_bus()
	if eb and eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.disconnect(_on_entity_state_changed)

	var lifecycle := AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.clear_timers()


func _on_room_entered(p_room_index: int, room_data: Dictionary) -> void:
	if OS.is_debug_build():
		print(
			"[CombatRoom] _on_room_entered index:%d data_keys:%s" % [p_room_index, room_data.keys()]
		)

	var lifecycle := AutoloadHelper.entity_lifecycle()
	if lifecycle:
		lifecycle.clear_timers()

	_current_room_data = room_data
	_room_kills = 0

	# Clear existing entities if any
	for child: Node in entity_container.get_children():
		entity_container.remove_child(child)
		child.queue_free()

	_create_enemies_node()

	if _boss_entity and _boss_entity.hp_changed.is_connected(_on_boss_hp_changed):
		_boss_entity.hp_changed.disconnect(_on_boss_hp_changed)

	# Configure grid
	RoomLoader.configure_grid(room_data)

	# Spawn entities
	_player = RoomLoader.spawn_entities(room_data, entity_container, _enemies_node)

	# Boss and reinforcements setup
	_boss_entity = null
	_reinforcements_spawned = false
	for child in _enemies_node.get_children():
		var e := CombatEntity.get_entity(child)
		if e and e.archetype_id == "overgrown_guardian":
			_boss_entity = e
			_boss_entity.hp_changed.connect(_on_boss_hp_changed)
			break

	# Show internal monologue on first room entry (room_index 0)
	if p_room_index == 0:
		var dm: _DialogueManager = AutoloadHelper.dialogue_manager()
		if dm != null:
			dm.show_internal_monologue("DIALOGUE_KEEPER_INTRO_1")

	# Setup combat systems
	if _combat_input:
		_combat_input.queue_free()
	_combat_input = CombatInput.new(_player, _enemies_node, grid_renderer)
	add_child(_combat_input)

	if _turn_manager:
		_turn_manager.queue_free()
	_setup_turn_manager()

	# Spawn props
	_spawn_props(room_data)

	# Center camera
	_setup_camera()

	# Setup HUD
	_setup_hud()


func _setup_hud() -> void:
	var combat_hud := $UIOverlay/CombatHUD as _CombatHUD
	if combat_hud and _player:
		var player_entity := CombatEntity.get_entity(_player)
		if player_entity:
			combat_hud.setup(player_entity, _turn_manager, _combat_input)
			if not combat_hud.move_pressed.is_connected(_on_hud_move_pressed):
				combat_hud.move_pressed.connect(_on_hud_move_pressed)

	var turn_banner_scene := load(TURN_BANNER_SCENE_PATH) as PackedScene
	if turn_banner_scene:
		var turn_banner := turn_banner_scene.instantiate()
		ui_overlay.add_child(turn_banner)


func _setup_turn_manager() -> void:
	_turn_manager = TurnManager.new()
	_turn_manager.name = "TurnManager"
	add_child(_turn_manager)

	_turn_manager.combat_ended.connect(_on_combat_ended)

	if not is_instance_valid(_player) or not is_instance_valid(_enemies_node):
		return

	var enemies: Array[Node2D] = []
	for child: Node in _enemies_node.get_children():
		if child is Node2D:
			enemies.append(child)

	if not enemies.is_empty():
		_turn_manager.start_combat(_player, enemies)


func _spawn_props(room_data: Dictionary) -> void:
	"""Spawn purely visual environmental props using deterministic seed placement."""
	var props_node: Node2D = $Environment/Props as Node2D
	if props_node == null:
		return

	# Clear existing props
	for child: Node in props_node.get_children():
		props_node.remove_child(child)
		child.queue_free()

	var seed_val: int = room_data.get("encounter_seed", 12345)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Spawn 2-3 rock/debris placeholders at static grid locations
	var prop_count: int = rng.randi_range(2, 3)
	for i: int in range(prop_count):
		var gx: int = rng.randi_range(2, 9)
		var gy: int = rng.randi_range(2, 9)
		var pos: Vector2 = (
			grid_renderer._grid_to_world(gx, gy, 0) if grid_renderer else Vector2(gx * 32, gy * 16)
		)

		var rock: ColorRect = ColorRect.new()
		rock.name = "Rock_%d" % i
		rock.size = Vector2(8, 6)
		rock.color = Color(0.4, 0.38, 0.36, 1.0)
		rock.position = pos - Vector2(4, 3)
		props_node.add_child(rock)


func _create_enemies_node() -> void:
	_enemies_node = Node2D.new()
	_enemies_node.name = "Enemies"
	_enemies_node.y_sort_enabled = true
	entity_container.add_child(_enemies_node)


func _load_demo_room() -> void:
	"""Load a curated demo room when no RunManager is present (e.g. direct scene launch)."""
	var room_data := RoomLoader.load_room_data("room_standard_01")
	if room_data.is_empty():
		# Fallback if file not found
		room_data = {
			"encounter_seed": 12345,
			"biome": 0,
			"room_in_biome": 0,
			"player_start": {"x": 1, "y": 1}
		}
	else:
		room_data["encounter_seed"] = 12345
		room_data["biome"] = 0
		room_data["room_in_biome"] = 0

	RoomLoader.augment_room_procedurally(room_data)
	_on_room_entered(0, room_data)


func _load_tutorial_room_data() -> Dictionary:
	"""Load the tutorial room for first-time players (room 0, no save)."""
	var room_data := RoomLoader.load_room_data("room_tutorial")
	if room_data.is_empty():
		# Fallback if tutorial room file not found
		room_data = {
			"id": "room_tutorial",
			"encounter_seed": 12345,
			"biome": 0,
			"room_in_biome": 0,
			"player_start": {"x": 1, "y": 1},
			"encounters": [{"enemy_type": "grunt", "count": 1, "positions": [{"x": 10, "y": 10}]}],
			"layout": {"elevation": [], "cover": [], "blocked": [], "vision_blocked": []},
			"tutorial_hint": "TUTORIAL_MOVE_HINT"
		}
	# Ensure layout arrays are sized to 144 if empty
	var layout: Dictionary = room_data.get("layout", {}) as Dictionary
	for key: String in ["elevation", "cover"]:
		var arr: Array = layout.get(key, []) as Array
		while arr.size() < 144:
			arr.append(0)
		layout[key] = arr
	for key: String in ["blocked", "vision_blocked"]:
		var arr: Array = layout.get(key, []) as Array
		while arr.size() < 144:
			arr.append(false)
		layout[key] = arr
	room_data["layout"] = layout
	return room_data


func _setup_camera() -> void:
	# Camera centered on grid (approximate center of 12x12 grid)
	camera.zoom = Vector2(4.5, 4.5)
	if grid_renderer:
		camera.position = grid_renderer.grid_to_world(5, 5, 0)


func _unhandled_input(event: InputEvent) -> void:
	if _turn_manager == null or _turn_manager.current_state != TurnManager.CombatState.PLAYER_TURN:
		return

	# Delegate to combat input handler
	if _combat_input and _combat_input.handle_input(event):
		return

	# Handle player movement via Input Actions
	if event.is_action_pressed("move_up"):
		_try_move_player(0, -1)
	elif event.is_action_pressed("move_down"):
		_try_move_player(0, 1)
	elif event.is_action_pressed("move_left"):
		_try_move_player(-1, 0)
	elif event.is_action_pressed("move_right"):
		_try_move_player(1, 0)
	elif event.is_action_pressed("combat_end_turn"):
		if _combat_input.current_state == CombatInput.State.TARGETING:
			_combat_input._stop_targeting()
		_turn_manager.end_player_turn()


func _try_move_player(dx: int, dy: int) -> void:
	var entity := CombatEntity.get_entity(_player)
	if not entity:
		return

	# Consume AP for movement
	var cost: int = CombatFormula.action_cost("move_cardinal")
	if entity.ap < cost:
		return

	var new_x: int = entity.x + dx
	var new_y: int = entity.y + dy

	if _grid_system and _grid_system.can_move(entity.x, entity.y, new_x, new_y):
		entity.set_grid_position(new_x, new_y)
		# Facing update
		entity.set_facing(dx, dy)
		# Deduct AP
		entity.ap -= cost


func _on_hud_move_pressed() -> void:
	# For Sprint 1, movement is direct via WASD/Arrows.
	# The HUD button provides feedback to the player.
	if _combat_input and _combat_input.current_state == CombatInput.State.TARGETING:
		_combat_input._stop_targeting()


func _on_combat_ended(victory: bool) -> void:
	if victory:
		if _boss_entity and _boss_entity.archetype_id == "overgrown_guardian":
			var rm := AutoloadHelper.run_manager()
			if rm:
				rm.cmd_final_encounter_won()
		_show_victory_modal()
	else:
		_show_defeat_modal()


func _on_boss_hp_changed(new_hp: int, _old_hp: int) -> void:
	if _boss_entity == null or _reinforcements_spawned:
		return

	if float(new_hp) / float(_boss_entity.hp_max) <= 0.5:
		_reinforcements_spawned = true
		_spawn_reinforcements()


func _spawn_reinforcements() -> void:
	if not _current_room_data.has("reinforcements"):
		return

	var an := AutoloadHelper.ambient_narrator()
	if an:
		an.trigger_narrative("narrative.boss.reinforcements")

	var reinforcements: Array = _current_room_data["reinforcements"] as Array
	for encounter: Variant in reinforcements:
		if encounter is Dictionary:
			var enc := encounter as Dictionary
			var enemy_type: String = enc.get("enemy_type", "grunt")
			var positions: Array = enc.get("positions", []) as Array

			var enemy_scene: PackedScene = RoomLoader.ENEMY_SCENES.get(
				enemy_type, RoomLoader.ENEMY_SCENES["grunt"]
			)
			if enemy_scene == null:
				continue

			for pos_data: Variant in positions:
				if not pos_data is Dictionary:
					continue
				var d := pos_data as Dictionary
				var x: int = int(d.get("x", 0))
				var y: int = int(d.get("y", 0))

				var enemy := enemy_scene.instantiate() as Node2D
				if "archetype_id" in enemy:
					var arch_override: String = enc.get("archetype_override", "")
					if not arch_override.is_empty():
						enemy.set("archetype_id", arch_override)
					else:
						enemy.set("archetype_id", enemy_type)

				if "elite_type" in enemy:
					enemy.set("elite_type", enc.get("elite_type", ""))

				if "behavior_override" in enemy:
					enemy.set("behavior_override", enc.get("behavior_override", ""))

				_enemies_node.add_child(enemy)

				var entity: Entity = CombatEntity.get_entity(enemy)
				if entity:
					entity.set_grid_position(x, y)
					if _turn_manager:
						_turn_manager.add_enemy(enemy)


func _on_entity_state_changed(
	entity: Entity, old_state: Entity.State, new_state: Entity.State
) -> void:
	# Only increment kills if transitioning from a non-dead/non-ghost state to DEAD or GHOST
	var was_alive := old_state != Entity.State.DEAD and old_state != Entity.State.GHOST
	var is_now_dead := new_state == Entity.State.DEAD or new_state == Entity.State.GHOST

	if not entity.is_player and was_alive and is_now_dead:
		_room_kills += 1


func _calculate_shards() -> int:
	var config := AutoloadHelper.config_loader()
	if not config:
		return 0

	var rewards: Dictionary = config.getValue("rewards", "victory_reward", {})
	var min_shards: int = int(rewards.get("shards_min", 20))
	var max_shards: int = int(rewards.get("shards_max", 50))
	var shard_range: int = max_shards - min_shards + 1

	var enc_seed: int = int(_current_room_data.get("encounter_seed", 0))
	var bonus: int = SeedGovernance.modulo_from_seed(enc_seed, "VICTORY_SHARDS", shard_range)
	return min_shards + bonus


func _show_victory_modal() -> void:
	var scene: PackedScene = load(VICTORY_MODAL_SCENE_PATH)
	if scene:
		var modal := scene.instantiate() as _VictoryModal
		ui_overlay.add_child(modal)
		if modal:
			var summary: Dictionary = {
				"turns": _turn_manager.round_number,
				"kills": _room_kills,
				"shards": _calculate_shards(),
			}
			modal.setup(summary)


func _show_defeat_modal() -> void:
	var scene: PackedScene = load(DEFEAT_MODAL_SCENE_PATH)
	if scene:
		var modal := scene.instantiate() as _DefeatModal
		ui_overlay.add_child(modal)
		if modal:
			var rm: _RunManager = AutoloadHelper.run_manager()
			var summary: Dictionary = {
				"turns": _turn_manager.round_number,
				"rooms": rm.room_index if rm else 0,
			}
			modal.setup(summary)
