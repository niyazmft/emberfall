class_name CombatRoom
extends Node2D
## The root scene for all tactical gameplay.
## Handles the core visual architecture defined in AGENTS.md:
##   - GridRenderer: Isometric floor
##   - EntityContainer (YSort): Depth-sorted game entities
##   - UIOverlay: CanvasLayer for HUD and menus

const KEEPER_SCENE_PATH: String = "res://scenes/keeper.tscn"
const GRUNT_SCENE_PATH: String = "res://scenes/enemies/enemy_grunt.tscn"

@export var test_mode: bool = true  # Spawn test enemies

var _grid_system: _GridSystem
var _player: Node2D  # Type will be Keeper
var _enemies_node: Node2D
var _combat_input: CombatInput
var _turn_manager: TurnManager

@onready var grid_renderer: GridRenderer = $GridRenderer
@onready var entity_container: Node2D = $EntityContainer
@onready var ui_overlay: CanvasLayer = $UIOverlay
@onready var camera: CameraController = $Camera2D

static var instance: CombatRoom


func _ready() -> void:
	instance = self
	_grid_system = AutoloadHelper.grid_system()

	var run_manager := AutoloadHelper.run_manager()
	if run_manager:
		run_manager.room_entered.connect(_on_room_entered)
		# If we are already in a room, trigger it manually
		if run_manager.current_state == _RunManager.RunState.ROOM:
			_on_room_entered(run_manager.room_index, run_manager._get_current_room_data())
	elif test_mode:
		_spawn_test_encounter()

	_setup_camera()


func _on_room_entered(_room_index: int, room_data: Dictionary) -> void:
	# Clear existing entities if any
	for child in entity_container.get_children():
		child.queue_free()

	_enemies_node = Node2D.new()
	_enemies_node.name = "Enemies"
	entity_container.add_child(_enemies_node)

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
	_setup_turn_banner()


func _setup_hud() -> void:
	var combat_hud: Control = $UIOverlay/CombatHUD
	if combat_hud and _player:
		var player_entity: Entity = _player.get("entity") as Entity
		combat_hud.call("setup", player_entity, _turn_manager, _combat_input)


func _setup_turn_banner() -> void:
	var banner_scene: PackedScene = load("res://scenes/ui/turn_banner.tscn")
	if banner_scene:
		var banner: TurnBanner = banner_scene.instantiate() as TurnBanner
		ui_overlay.add_child(banner)

		if _turn_manager:
			_turn_manager.turn_started.connect(func(is_player_turn: bool) -> void:
				banner.show_banner("PLAYER TURN" if is_player_turn else "ENEMY TURN")
			)


func _setup_turn_manager() -> void:
	_turn_manager = TurnManager.new()
	_turn_manager.name = "TurnManager"
	add_child(_turn_manager)

	_turn_manager.combat_ended.connect(_on_combat_ended)

	if not is_instance_valid(_player) or not is_instance_valid(_enemies_node):
		return

	var enemies: Array[Node2D] = []
	for child in _enemies_node.get_children():
		if child is Node2D:
			enemies.append(child)

	if not enemies.is_empty() or test_mode:
		_turn_manager.start_combat(_player, enemies)


func _spawn_test_encounter() -> void:
	_spawn_player()
	_spawn_enemies()

	_combat_input = CombatInput.new(_player, _enemies_node, grid_renderer)
	add_child(_combat_input)
	_setup_turn_manager()
	_setup_hud()


func _spawn_player() -> void:
	var keeper_scene: PackedScene = load(KEEPER_SCENE_PATH)
	var keeper: Node2D = keeper_scene.instantiate() as Node2D

	# Initializing entity data block
	var entity_resource: Entity = Entity.new("Keeper", 5, 5, 40, 12, 6)
	entity_resource.is_player = true

	# Assigning entity to keeper before adding to tree if possible
	if keeper.has_method("set"):
		keeper.set("entity", entity_resource)

	_player = keeper
	entity_container.add_child(keeper)

	# Explicitly set position after adding to tree to trigger visual proxy if needed
	if _player.get("entity"):
		var entity: Entity = _player.get("entity") as Entity
		entity.set_grid_position(5, 5)


func _spawn_enemies() -> void:
	var grunt_scene: PackedScene = load(GRUNT_SCENE_PATH)

	_enemies_node = Node2D.new()
	_enemies_node.name = "Enemies"
	entity_container.add_child(_enemies_node)

	for i: int in range(3):  # Spawn 3 grunts
		var grunt: Node2D = grunt_scene.instantiate() as Node2D
		_enemies_node.add_child(grunt)

		# Position grunts
		var entity: Entity = grunt.get("entity") as Entity
		if entity:
			entity.set_grid_position(8 + i, 3 + i)


func _setup_camera() -> void:
	# Camera centered on grid (approximate center of 12x12 grid)
	if grid_renderer:
		camera.global_position = grid_renderer.grid_to_world(5, 5, 0)

	if _player:
		camera.set_target(_player)


func _input(event: InputEvent) -> void:
	if _turn_manager.current_state != TurnManager.CombatState.PLAYER_TURN:
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
	if not _player or not _player.get("entity"):
		return

	var entity: Entity = _player.get("entity") as Entity

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


func _on_combat_ended(victory: bool) -> void:
	if victory:
		print("Victory!")
	else:
		print("Defeat!")
