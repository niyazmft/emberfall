class_name RoomLoader
extends Node
## RoomLoader
## Reads room definitions from JSON and configures the grid, elevation,
## cover, and enemy encounters.

const ROOMS_PATH := "res://config/rooms/"
const KEEPER_SCENE_PATH := "res://scenes/keeper.tscn"
const ENEMY_SCENES := {
	"grunt": preload("res://scenes/enemies/enemy_grunt.tscn"),
	"archer": preload("res://scenes/enemies/enemy_archer.tscn"),
	"tank": preload("res://scenes/enemies/enemy_tank.tscn"),
	"mage": preload("res://scenes/enemies/enemy_mage.tscn"),
	"boss": preload("res://scenes/enemies/enemy_boss.tscn"),
	"overgrown_guardian": preload("res://scenes/enemies/enemy_boss.tscn")
}


## Load room JSON data by ID.
static func load_room_data(room_id: String) -> Dictionary:
	var path := ROOMS_PATH + room_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open room file: " + path)
		return {}

	var text := f.get_as_text()
	f.close()

	var data: Variant = JSON.parse_string(text)
	if data == null or not data is Dictionary:
		push_error("Failed to parse room JSON or data is not a Dictionary: " + path)
		return {}

	return data as Dictionary


## Configure the GridSystem with room layout.
static func configure_grid(room_data: Dictionary) -> void:
	var grid_system := AutoloadHelper.grid_system()
	if grid_system:
		grid_system.load_room(room_data)

		# Handle procedural hazards
		if room_data.has("hazards"):
			var hazards: Array = room_data["hazards"] as Array
			for hazard_data: Variant in hazards:
				if hazard_data is Dictionary:
					var h := hazard_data as Dictionary
					var x: int = int(h.get("x", 0))
					var y: int = int(h.get("y", 0))
					var type: String = h.get("type", "")
					if type == "oil":
						grid_system.set_oil_tile(x, y, true)
					elif type == "fire":
						# Map fire to oil handler as baseline or implement fire if GridSystem supports it
						# Memory says: GridSystem has apply_tile_element
						grid_system.apply_tile_element(x, y, ElementalTypes.ElementType.FIRE, 3, -1)
	else:
		push_error("GridSystem autoload not found")


## Augments the room data with procedural elements and encounters.
static func augment_room_procedurally(room_data: Dictionary) -> void:
	var topo_seed: int = int(room_data.get("topology_seed", 0))
	var applied_topo_seed: int = int(room_data.get("topology_seed_applied", -1))

	var enc_seed: int = int(room_data.get("encounter_seed", 0))
	var biome_idx: int = int(room_data.get("biome", 0))
	var biome_id := "biome%d" % (biome_idx + 1)
	var room_in_biome: int = int(room_data.get("room_in_biome", 0))

	# 1. Topology Augmentation (Idempotent)
	if applied_topo_seed != topo_seed:
		RoomGenerator.augmentRoom(room_data, biome_id, topo_seed)
		room_data["topology_seed_applied"] = topo_seed

	# 2. Encounter Generation and Scaling
	var target_difficulty: int = 1 + room_in_biome / 3

	if not room_data.has("encounters") or (room_data["encounters"] as Array).is_empty():
		var generated_encounters := EncounterSystem.buildEncounters(
			biome_id, enc_seed, target_difficulty
		)
		room_data["encounters"] = generated_encounters
	else:
		# Scale authored encounters
		var encounters: Array = room_data["encounters"]
		var scale_factor: float = 1.0 + float(room_in_biome) / 5.0
		for encounter_v: Variant in encounters:
			if encounter_v is Dictionary:
				var encounter := encounter_v as Dictionary
				var original_count: int = int(encounter.get("count", 1))
				var new_count: int = clampi(int(roundf(original_count * scale_factor)), 1, 10)
				encounter["count"] = new_count

	# 3. Always assign positions for backfilling and reservation
	_assign_default_positions(room_data, enc_seed)


static func _assign_default_positions(room_data: Dictionary, p_seed: int) -> void:
	## NOTE: RandomNumberGenerator is version-bound. Godot does NOT guarantee
	## identical sequences across engine releases (e.g., 4.6.3 -> 4.7).
	## Procedural room layouts from save files may differ when loaded on a
	## different Godot version. SaveManager stores the originating version
	## and warns on mismatch, but the layout divergence is unavoidable
	## without replacing this with a custom deterministic RNG (future work).
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed

	var layout: Dictionary = room_data.get("layout", {})
	var blocked: Array = layout.get("blocked", [])

	var encounters: Array = room_data.get("encounters", []) as Array
	var player_start: Dictionary = room_data.get("player_start", {"x": 1, "y": 1})
	var px: int = int(player_start.get("x", 1))
	var py: int = int(player_start.get("y", 1))

	var reserved: Array[Vector2i] = [Vector2i(px, py)]

	# First pass: Collect all existing authored positions
	for encounter_variant: Variant in encounters:
		if not encounter_variant is Dictionary:
			continue
		var encounter := encounter_variant as Dictionary
		var positions: Array = encounter.get("positions", []) as Array
		for pos_data: Variant in positions:
			if pos_data is Dictionary:
				var d := pos_data as Dictionary
				reserved.append(Vector2i(int(d.get("x", 0)), int(d.get("y", 0))))

	# Second pass: Backfill missing positions
	for encounter_variant: Variant in encounters:
		if not encounter_variant is Dictionary:
			continue
		var encounter := encounter_variant as Dictionary
		var positions: Array = encounter.get("positions", []) as Array
		var target_count: int = int(encounter.get("count", 1))

		while positions.size() < target_count:
			var found := false
			for attempt: int in range(200):
				var rx := rng.randi_range(0, 11)
				var ry := rng.randi_range(0, 11)
				var rpos := Vector2i(rx, ry)

				# Basic heuristic: spawn on opposite side of player if possible
				if attempt < 100:
					if px < 6 and rx < 6:
						continue
					if px >= 6 and rx >= 6:
						continue

				var idx := ry * 12 + rx
				if idx < blocked.size() and bool(blocked[idx]):
					continue
				if rpos in reserved:
					continue

				positions.append({"x": rx, "y": ry})
				reserved.append(rpos)
				found = true
				break
			if not found:
				# Last resort: just pick first available
				for idx: int in range(144):
					var rx := idx % 12
					var ry := idx / 12
					var rpos := Vector2i(rx, ry)
					if not bool(blocked[idx]) and not rpos in reserved:
						positions.append({"x": rx, "y": ry})
						reserved.append(rpos)
						found = true
						break
				if not found:
					break  # No more space
		encounter["positions"] = positions


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

	if keeper is Keeper:
		(keeper as Keeper).entity = entity_resource

	container.add_child(keeper)

	var x: int = int(start_pos.get("x", 1))
	var y: int = int(start_pos.get("y", 1))
	entity_resource.set_grid_position(x, y)

	return keeper


static func _spawn_encounter(encounter: Dictionary, container: Node, enemies_node: Node) -> void:
	var enemy_type: String = encounter.get("enemy_type", "grunt")
	var positions: Array = encounter.get("positions", []) as Array

	var enemy_scene: PackedScene = ENEMY_SCENES.get(enemy_type, ENEMY_SCENES["grunt"])
	if enemy_scene == null:
		push_error("Failed to get enemy scene for type: " + enemy_type)
		return

	for pos_data: Variant in positions:
		if not pos_data is Dictionary:
			continue
		var d := pos_data as Dictionary
		var x: int = int(d.get("x", 0))
		var y: int = int(d.get("y", 0))

		var enemy := enemy_scene.instantiate() as Node2D
		if "archetype_id" in enemy:
			var arch_override: String = encounter.get("archetype_override", "")
			if not arch_override.is_empty():
				enemy.set("archetype_id", arch_override)
			else:
				enemy.set("archetype_id", enemy_type)

		if "elite_type" in enemy:
			enemy.set("elite_type", encounter.get("elite_type", ""))

		if "behavior_override" in enemy:
			enemy.set("behavior_override", encounter.get("behavior_override", ""))

		if enemies_node:
			enemies_node.add_child(enemy)
		else:
			container.add_child(enemy)

		var entity: Entity = CombatEntity.get_entity(enemy)
		if entity:
			entity.set_grid_position(x, y)
		else:
			# If entity wasn't initialized in _ready of BaseEnemy for some reason
			# Or if we want to override it
			pass
