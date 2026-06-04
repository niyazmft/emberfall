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

@onready var grid_renderer: GridRenderer = $GridRenderer
@onready var entity_container: Node2D = $EntityContainer
@onready var ui_overlay: CanvasLayer = $UIOverlay
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_grid_system = AutoloadHelper.grid_system()

	if test_mode:
		_spawn_test_encounter()

	if _player and _enemies_node:
		_combat_input = CombatInput.new(_player, _enemies_node, grid_renderer)
		add_child(_combat_input)
	else:
		push_warning("CombatRoom: _player or _enemies_node is null. CombatInput will not be initialized.")

	_setup_camera()


func _spawn_test_encounter() -> void:
	_spawn_player()
	_spawn_enemies()


func _spawn_player() -> void:
	var keeper_scene: PackedScene = preload(KEEPER_SCENE_PATH)
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
	var grunt_scene: PackedScene = preload(GRUNT_SCENE_PATH)

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
		camera.position = grid_renderer.grid_to_world(5, 5, 0)


func _input(event: InputEvent) -> void:
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


func _try_move_player(dx: int, dy: int) -> void:
	if not _player or not _player.get("entity"):
		return

	var entity: Entity = _player.get("entity") as Entity
	var new_x: int = entity.x + dx
	var new_y: int = entity.y + dy

	if _grid_system and _grid_system.can_move(entity.x, entity.y, new_x, new_y):
		entity.set_grid_position(new_x, new_y)
		# Facing update
		entity.set_facing(dx, dy)
