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
var _reflection_text: String = ""
var _current_room_data: Dictionary = {}
var _boss_entity: Entity = null
var _reinforcements_spawned: bool = false

@onready var grid_renderer: GridRenderer = $GridRenderer
@onready var entity_container: Node2D = $EntityContainer
@onready var floating_text_container: Node2D = $EntityContainer/FloatingTextContainer
@onready var ui_overlay: CanvasLayer = $UIOverlay
@onready var camera: Camera2D = $Camera2D

## Camera follow / shake state
var _camera_target: Node2D = null
var _camera_shake_time: float = 0.0
var _camera_shake_intensity: float = 0.0
var _camera_shake_seed: int = 0
const CAMERA_FOLLOW_SPEED: float = 3.0
const CAMERA_SHAKE_DURATION: float = 0.2
const CAMERA_SHAKE_MAX_OFFSET: float = 4.0


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

	# FIX #590: Wire burden narrative modal when moral weight threshold is crossed.
	var lifecycle := AutoloadHelper.entity_lifecycle()
	if lifecycle and not lifecycle.mwt_reached.is_connected(_on_mwt_reached):
		lifecycle.mwt_reached.connect(_on_mwt_reached)

	_setup_camera()


func _exit_tree() -> void:
	var run_manager := AutoloadHelper.run_manager()
	if run_manager and run_manager.room_entered.is_connected(_on_room_entered):
		run_manager.room_entered.disconnect(_on_room_entered)

	var eb := AutoloadHelper.event_bus()
	if eb and eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.disconnect(_on_entity_state_changed)

	# FIX #590: Disconnect burden narrative signal and clear timers.
	var lifecycle := AutoloadHelper.entity_lifecycle()
	if lifecycle:
		if lifecycle.mwt_reached.is_connected(_on_mwt_reached):
			lifecycle.mwt_reached.disconnect(_on_mwt_reached)
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
	_combat_input.attack_executed.connect(_on_attack_executed)

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
	_turn_manager.reflection_started.connect(_on_reflection_started)
	_turn_manager.turn_started.connect(_on_turn_started)

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
	if props_node == null or entity_container == null:
		return

	# Clear existing props
	for child: Node in props_node.get_children():
		props_node.remove_child(child)
		child.queue_free()

	var seed_val: int = room_data.get("encounter_seed", 12345)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var pillar_tex: Texture2D = (
		load("res://assets/sprites/props/prop_broken_pillar.png") as Texture2D
	)
	var rock_tex: Texture2D = load("res://assets/sprites/props/prop_rock.png") as Texture2D

	# Spawn 3-5 tall environmental props in entity_container for YSort occlusion testing
	var tall_count: int = rng.randi_range(3, 5)
	for i: int in range(tall_count):
		var gx: int = rng.randi_range(2, 9)
		var gy: int = rng.randi_range(2, 9)
		var pos: Vector2 = (
			grid_renderer._grid_to_world(gx, gy, 0) if grid_renderer else Vector2(gx * 32, gy * 16)
		)

		var prop: Sprite2D = Sprite2D.new()
		prop.name = "Prop_%d" % i
		prop.texture = pillar_tex if i % 2 == 0 and pillar_tex != null else rock_tex
		prop.position = pos
		prop.scale = Vector2(0.4, 0.4)
		prop.offset = Vector2(0, -32)  # Offset upwards so base aligns with YSort position
		entity_container.add_child(prop)


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


func _process(delta: float) -> void:
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	## Smoothly interpolate camera position toward the target entity.
	var desired_pos: Vector2 = camera.position

	if _camera_target != null and is_instance_valid(_camera_target):
		desired_pos = _camera_target.position
	elif grid_renderer:
		desired_pos = grid_renderer.grid_to_world(5, 5, 0)

	var follow_weight: float = DeterministicMath.clampf(CAMERA_FOLLOW_SPEED * delta, 0.0, 1.0)
	desired_pos = camera.position.lerp(desired_pos, follow_weight)

	if _camera_shake_time > 0.0:
		var decay: float = _camera_shake_time / CAMERA_SHAKE_DURATION
		var current_intensity: float = _camera_shake_intensity * decay
		var seed_x: int = _camera_shake_seed + int(_camera_shake_time * 1000.0)
		var seed_y: int = _camera_shake_seed + int(_camera_shake_time * 1000.0) + 1
		var frac_x: float = SeedGovernance.fract_from_seed(seed_x)
		var frac_y: float = SeedGovernance.fract_from_seed(seed_y)
		var offset_x: float = DeterministicMath.clampf(
			(frac_x * 2.0 - 1.0) * current_intensity,
			-CAMERA_SHAKE_MAX_OFFSET,
			CAMERA_SHAKE_MAX_OFFSET
		)
		var offset_y: float = DeterministicMath.clampf(
			(frac_y * 2.0 - 1.0) * current_intensity,
			-CAMERA_SHAKE_MAX_OFFSET,
			CAMERA_SHAKE_MAX_OFFSET
		)
		desired_pos += Vector2(offset_x, offset_y)
		_camera_shake_time = DeterministicMath.clampf(
			_camera_shake_time - delta, 0.0, CAMERA_SHAKE_DURATION
		)

	camera.position = desired_pos

	_clamp_camera_position()


func trigger_camera_shake(intensity: float = CAMERA_SHAKE_MAX_OFFSET) -> void:
	_camera_shake_seed += 1
	_camera_shake_time = CAMERA_SHAKE_DURATION
	_camera_shake_intensity = intensity


func _setup_camera() -> void:
	# Camera centered on grid (approximate center of 12x12 grid)
	camera.zoom = Vector2(2.8, 2.8)
	if grid_renderer:
		camera.position = grid_renderer.grid_to_world(5, 5, 0)


func _clamp_camera_position() -> void:
	if not grid_renderer:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size / camera.zoom
	var half_view: Vector2 = viewport_size / 2.0

	# Compute grid world bounds from the four corners.
	var corners: Array[Vector2] = [
		grid_renderer.grid_to_world(0, 0, 0),
		grid_renderer.grid_to_world(11, 0, 0),
		grid_renderer.grid_to_world(0, 11, 0),
		grid_renderer.grid_to_world(11, 11, 0),
	]

	var min_x: float = corners[0].x
	var max_x: float = corners[0].x
	var min_y: float = corners[0].y
	var max_y: float = corners[0].y
	for corner: Vector2 in corners:
		min_x = minf(min_x, corner.x)
		max_x = maxf(max_x, corner.x)
		min_y = minf(min_y, corner.y)
		max_y = maxf(max_y, corner.y)

	# Add padding (half a tile)
	var pad: float = 32.0
	min_x -= pad
	max_x += pad
	min_y -= pad
	max_y += pad

	var clamp_min: Vector2 = Vector2(min_x + half_view.x, min_y + half_view.y)
	var clamp_max: Vector2 = Vector2(max_x - half_view.x, max_y - half_view.y)

	# If viewport is larger than the padded grid, clamp to center.
	if clamp_min.x > clamp_max.x:
		clamp_min.x = (min_x + max_x) / 2.0
		clamp_max.x = clamp_min.x
	if clamp_min.y > clamp_max.y:
		clamp_min.y = (min_y + max_y) / 2.0
		clamp_max.y = clamp_min.y

	camera.position.x = DeterministicMath.clampf(camera.position.x, clamp_min.x, clamp_max.x)
	camera.position.y = DeterministicMath.clampf(camera.position.y, clamp_min.y, clamp_max.y)


func _unhandled_input(event: InputEvent) -> void:
	if _turn_manager == null or _turn_manager.current_state != TurnManager.CombatState.PLAYER_TURN:
		return

	# Delegate to combat input handler first (handles targeting cancel on right-click)
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
		# FIX #589: Save progress before showing victory modal.
		_save_run_progress()
		_show_victory_modal()
	else:
		_show_defeat_modal()


func _on_mwt_reached(_moral_flag: int, _remaining_deltas: int) -> void:
	"""FIX #590: Show burden narrative modal when moral weight threshold is crossed."""
	var rm: _RunManager = AutoloadHelper.run_manager()
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if rm == null or bm == null:
		return

	# Generate the burden event narrative deterministically.
	var is_first: bool = bm._burden_trigger_count == 0
	var result: BurdenEventResult = bm.trigger_burden_event(
		rm.run_seed, rm.run_seed, rm.room_index, 0, is_first
	)

	# Pause and show modal.
	get_tree().paused = true
	var modal := _BurdenNarrativeModal.new()
	modal.process_mode = Node.PROCESS_MODE_ALWAYS
	modal.setup(result)
	ui_overlay.add_child(modal)

	modal.continued.connect(
		func() -> void:
			get_tree().paused = false
			if rm:
				rm.cmd_flags_updated()
	)


func _save_run_progress() -> void:
	"""Build and persist the current run state so Continue works across rooms."""
	var sm: _SaveManager = AutoloadHelper.save_manager()
	var rm: _RunManager = AutoloadHelper.run_manager()
	if sm == null or rm == null:
		push_warning("CombatRoom: Cannot save — SaveManager or RunManager missing.")
		return

	var run_state: Dictionary = rm.save_run_state()
	var player_snapshot: Dictionary = {}
	var burden_snapshot: Dictionary = {}
	var inventory_snapshot: Dictionary = {}

	if _player != null and is_instance_valid(_player):
		var player_ent: Entity = CombatEntity.get_entity(_player)
		if player_ent != null:
			player_snapshot = {
				"hp": player_ent.hp,
				"hp_max": player_ent.hp_max,
				"ap": player_ent.ap,
			}

	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm != null:
		burden_snapshot = {
			"mwt_level": bm.current_mwt_level,
			"total_sentient_kills": bm.total_sentient_kills,
		}

	var inv_mgr: _InventoryManager = AutoloadHelper.inventory_manager()
	if inv_mgr != null:
		inventory_snapshot = {
			"items": inv_mgr.inventory.duplicate(true),
			"equipment": inv_mgr.equipment.duplicate(true),
		}

	var state: Dictionary = {
		"version": 1,
		"run_state": run_state,
		"player_entity_snapshot": player_snapshot,
		"burden_run_snapshot": burden_snapshot,
		"inventory_snapshot": inventory_snapshot,
		"meta":
		{
			"schema_version": "1.0.0",
			"save_timestamp_iso": Time.get_datetime_string_from_system(),
			"platform": OS.get_name(),
		},
	}

	var err: Error = sm.save_game(state)
	if err != OK:
		push_warning("CombatRoom: save_game failed with error %d." % err)


func _on_reflection_started(text: String) -> void:
	_reflection_text = text


func _on_turn_started(entity: Entity, is_player: bool) -> void:
	## Set camera target to the active entity's visual node.
	if is_player and _player != null and is_instance_valid(_player):
		_camera_target = _player
	else:
		## Find the enemy Node2D that owns this entity.
		for child: Node in _enemies_node.get_children():
			if child is Node2D:
				var child_ent := CombatEntity.get_entity(child)
				if child_ent == entity:
					_camera_target = child
					break


func _on_attack_executed(_target: Node2D, _damage: int) -> void:
	## Brief camera shake on attack impact.
	trigger_camera_shake(CAMERA_SHAKE_MAX_OFFSET)


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
	get_tree().paused = true
	var scene: PackedScene = load(VICTORY_MODAL_SCENE_PATH)
	if scene:
		var modal := scene.instantiate() as _VictoryModal
		ui_overlay.add_child(modal)
		if modal:
			if not _reflection_text.is_empty():
				modal.show_reflection(_reflection_text)
			var summary: Dictionary = {
				"turns": _turn_manager.round_number,
				"kills": _room_kills,
				"shards": _calculate_shards(),
			}
			modal.setup(summary)


func _show_defeat_modal() -> void:
	get_tree().paused = true
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
