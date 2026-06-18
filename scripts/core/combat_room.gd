class_name CombatRoom
extends Node2D
## The root scene for all tactical gameplay.
## Handles the core visual architecture defined in AGENTS.md:
##   - GridRenderer: Isometric floor
##   - EntityContainer (YSort): Depth-sorted game entities
##   - UIOverlay: CanvasLayer for HUD and menus

const VICTORY_MODAL_SCENE_PATH: String = "res://scenes/ui/victory_modal.tscn"
const DEFEAT_MODAL_SCENE_PATH: String = "res://scenes/ui/defeat_modal.tscn"

@export var test_mode: bool = true  # Spawn test enemies

var _grid_system: _GridSystem
var _player: Node2D  # Type will be Keeper
var _enemies_node: Node2D
var _combat_input: CombatInput
var _turn_manager: TurnManager
var _room_kills: int = 0
var _current_room_data: Dictionary = {}

@onready var grid_renderer: GridRenderer = $GridRenderer
@onready var entity_container: Node2D = $EntityContainer
@onready var ui_overlay: CanvasLayer = $UIOverlay
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_grid_system = AutoloadHelper.grid_system()

	var run_manager := AutoloadHelper.run_manager()
	if run_manager:
		run_manager.room_entered.connect(_on_room_entered)
		# If we are already in a room, trigger it manually
		if run_manager.current_state == _RunManager.RunState.ROOM:
			_on_room_entered(run_manager.room_index, run_manager.get_current_room_data())
	elif test_mode:
		_spawn_test_encounter()

	var eb := AutoloadHelper.event_bus()
	if eb:
		eb.entity_state_changed.connect(_on_entity_state_changed)

	_setup_camera()


func _exit_tree() -> void:
	var run_manager := AutoloadHelper.run_manager()
	if run_manager and run_manager.room_entered.is_connected(_on_room_entered):
		run_manager.room_entered.disconnect(_on_room_entered)

	var eb := AutoloadHelper.event_bus()
	if eb and eb.entity_state_changed.is_connected(_on_entity_state_changed):
		eb.entity_state_changed.disconnect(_on_entity_state_changed)


func _on_room_entered(p_room_index: int, room_data: Dictionary) -> void:
	if OS.is_debug_build():
		print(
			"[CombatRoom] _on_room_entered index:%d data_keys:%s" % [p_room_index, room_data.keys()]
		)
	_current_room_data = room_data
	_room_kills = 0

	# Clear existing entities if any
	for child: Node in entity_container.get_children():
		child.queue_free()

	_create_enemies_node()

	# Configure grid
	RoomLoader.configure_grid(room_data)

	# Spawn entities
	_player = RoomLoader.spawn_entities(room_data, entity_container, _enemies_node)

	# Setup combat systems
	if _combat_input:
		_combat_input.queue_free()
	_combat_input = CombatInput.new(_player, _enemies_node, grid_renderer)
	add_child(_combat_input)

	if _turn_manager:
		_turn_manager.queue_free()
	_setup_turn_manager()

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

	if not enemies.is_empty() or test_mode:
		_turn_manager.start_combat(_player, enemies)


func _create_enemies_node() -> void:
	_enemies_node = Node2D.new()
	_enemies_node.name = "Enemies"
	_enemies_node.y_sort_enabled = true
	entity_container.add_child(_enemies_node)


func _spawn_test_encounter() -> void:
	_room_kills = 0
	var room_data := RoomLoader.load_room_data("room_standard_01")
	if room_data.is_empty():
		# Fallback if file not found
		room_data = {
			"encounter_seed": 12345,
			"biome": 0,
			"room_in_biome": 0,
			"player_start": {"x": 5, "y": 5}
		}
	else:
		room_data["encounter_seed"] = 12345
		room_data["biome"] = 0
		room_data["room_in_biome"] = 0

	RoomLoader.augment_room_procedurally(room_data)
	_on_room_entered(0, room_data)


func _setup_camera() -> void:
	# Camera centered on grid (approximate center of 12x12 grid)
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

		var sfx := AutoloadHelper.sfx_manager()
		if sfx:
			sfx.play_sfx("move", _player.global_position)


func _on_hud_move_pressed() -> void:
	# For Sprint 1, movement is direct via WASD/Arrows.
	# The HUD button provides feedback to the player.
	if _combat_input and _combat_input.current_state == CombatInput.State.TARGETING:
		_combat_input._stop_targeting()


func _on_combat_ended(victory: bool) -> void:
	if victory:
		_showVictoryModal()
	else:
		_showDefeatModal()


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


func _showVictoryModal() -> void:
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


func _showDefeatModal() -> void:
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
