class_name RoomLoader
extends Node
## RoomLoader
## Reads room definitions from JSON and configures the grid, elevation,
## cover, and enemy encounters.

const ROOMS_PATH := "res://config/rooms/"
const KEEPER_SCENE_PATH := "res://scenes/keeper.tscn"
const ENEMY_SCENES := {"grunt": "res://scenes/enemies/enemy_grunt.tscn"}


## Load room JSON data by ID.
static func load_room_data(room_id: String, biome_subpath: String = "") -> Dictionary:
	var path := ROOMS_PATH
	if not biome_subpath.is_empty():
		path = path.path_join(biome_subpath)
	path = path.path_join(room_id + ".json")

	if not FileAccess.file_exists(path):
		# Fallback to root for standard rooms
		var fallback_path := ROOMS_PATH.path_join(room_id + ".json")
		if FileAccess.file_exists(fallback_path):
			path = fallback_path
		else:
			return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open room file: " + path)
		return {}

	var text := f.get_as_text()
	f.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("Failed to parse room JSON: " + path + " Error: " + json.get_error_message())
		return {}

	if not json.data is Dictionary:
		push_error("Room JSON data is not a Dictionary: " + path)
		return {}

	return json.data as Dictionary


## Configure the GridSystem with room layout.
static func configure_grid(room_data: Dictionary) -> void:
	var grid_system := AutoloadHelper.grid_system()
	if grid_system:
		grid_system.load_room(room_data)
	else:
		push_error("GridSystem autoload not found")


## Spawn player and enemies based on room data.
static func spawn_entities(
	room_data: Dictionary, entity_container: Node, enemies_node: Node
) -> Node2D:
	if entity_container == null:
		push_error("Entity container is null")
		return null

	# 1. Spawn Player
	var player_start: Dictionary = room_data.get("player_start", {"x": 1, "y": 1})
	var player := _spawn_player(player_start, entity_container)

	# 2. Spawn Encounters
	var encounters: Array = room_data.get("encounters", []) as Array
	for encounter: Variant in encounters:
		if encounter is Dictionary:
			_spawn_encounter(encounter as Dictionary, entity_container, enemies_node)

	return player


static func _spawn_player(start_pos: Dictionary, container: Node) -> Node2D:
	var keeper_scene := load(KEEPER_SCENE_PATH) as PackedScene
	if keeper_scene == null:
		push_error("Failed to load Keeper scene")
		return null

	var keeper := keeper_scene.instantiate() as Node2D

	# Entity data block
	var entity_resource := Entity.new("Keeper", 5, 5, 40, 12, 6)
	entity_resource.is_player = true

	if keeper.has_method("set"):
		keeper.set("entity", entity_resource)

	container.add_child(keeper)

	var x: int = int(start_pos.get("x", 1))
	var y: int = int(start_pos.get("y", 1))
	entity_resource.set_grid_position(x, y)

	return keeper


static func _spawn_encounter(encounter: Dictionary, container: Node, enemies_node: Node) -> void:
	var enemy_type: String = encounter.get("enemy_type", "grunt")
	var positions: Array = encounter.get("positions", []) as Array

	var scene_path: String = ENEMY_SCENES.get(enemy_type, ENEMY_SCENES["grunt"])
	var enemy_scene := load(scene_path) as PackedScene
	if enemy_scene == null:
		push_error("Failed to load enemy scene: " + scene_path)
		return

	for pos_data: Variant in positions:
		if not pos_data is Dictionary:
			continue
		var d := pos_data as Dictionary
		var x: int = int(d.get("x", 0))
		var y: int = int(d.get("y", 0))

		var enemy := enemy_scene.instantiate() as Node2D
		if enemies_node:
			enemies_node.add_child(enemy)
		else:
			container.add_child(enemy)

		var entity: Entity = enemy.get("entity") as Entity
		if entity:
			entity.set_grid_position(x, y)
		else:
			# If entity wasn't initialized in _ready of BaseEnemy for some reason
			# Or if we want to override it
			pass
