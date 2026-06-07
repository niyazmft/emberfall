class_name RoomGenerator
extends Node
## RoomGenerator
## Augments authored room layouts with procedural elements (cover, elevation,
## hazards, blocked tiles) using a deterministic seed and biome templates.

const BIOMES_CONFIG_PATH := "res://config/biomes.json"


## Augments the provided room_data with procedural elements based on biome rules.
static func augment_room(room_data: Dictionary, biome_id: String, topology_seed: int) -> void:
	var biome_params := _get_biome_params(biome_id)
	if biome_params.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = topology_seed

	if not room_data.has("layout"):
		room_data["layout"] = _create_empty_layout()

	var layout: Dictionary = room_data["layout"]
	var elevation: Array = layout.get("elevation", [])
	var cover: Array = layout.get("cover", [])
	var blocked: Array = layout.get("blocked", [])
	var vision: Array = layout.get("vision_blocked", [])

	# Ensure arrays are correct size (144 for 12x12)
	_ensure_layout_size(elevation, 0)
	_ensure_layout_size(cover, 0)
	_ensure_layout_size(blocked, false)
	_ensure_layout_size(vision, false)

	var gen_params: Dictionary = biome_params.get("generation_params", {})
	var cover_density: float = gen_params.get("cover_density", 0.1)
	var blocked_density: float = gen_params.get("blocked_density", 0.05)
	var hazard_density: float = gen_params.get("hazard_density", 0.0)
	var hazard_types: Array = gen_params.get("hazard_types", [])
	var elev_min: int = int(gen_params.get("elevation_min", 0))
	var elev_max: int = int(gen_params.get("elevation_max", 0))

	# Keep track of reserved positions (player start and explicitly placed enemies)
	var reserved_positions := _get_reserved_positions(room_data)

	for i in range(144):
		var x := i % 12
		var y := i / 12
		var pos := Vector2i(x, y)

		if reserved_positions.has(pos):
			continue

		# 1. Blocked Tiles (if not already blocked)
		if not blocked[i] and rng.randf() < blocked_density:
			blocked[i] = true
			vision[i] = true  # Usually blocked tiles also block vision
			continue  # If blocked, don't place other things

		# 2. Elevation (if currently 0)
		if elevation[i] == 0:
			if rng.randf() < 0.2:  # 20% chance to attempt elevation change
				elevation[i] = rng.randi_range(elev_min, elev_max)

		# 3. Cover (if not blocked and no cover)
		if not blocked[i] and cover[i] == 0:
			if rng.randf() < cover_density:
				# 70% light cover, 30% heavy cover
				cover[i] = 1 if rng.randf() < 0.7 else 2

		# 4. Hazards (placed in hazards array if we had one, otherwise tags or special handling)
		# For now, we'll use a "hazards" key in room_data or just ignore for this baseline
		# The prompt mentions hazards, so let's add a "hazards" array to room_data if it doesn't exist
		if rng.randf() < hazard_density and not hazard_types.is_empty():
			var hazard_type: String = hazard_types[rng.randi() % hazard_types.size()]
			_add_hazard(room_data, x, y, hazard_type)


static func _get_biome_params(biome_id: String) -> Dictionary:
	var f := FileAccess.open(BIOMES_CONFIG_PATH, FileAccess.READ)
	if not f:
		return {}
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err != OK:
		return {}
	var data: Dictionary = json.data
	return data.get(biome_id, {})


static func _create_empty_layout() -> Dictionary:
	var elevation := []
	var cover := []
	var blocked := []
	var vision := []
	elevation.resize(144)
	elevation.fill(0)
	cover.resize(144)
	cover.fill(0)
	blocked.resize(144)
	blocked.fill(false)
	vision.resize(144)
	vision.fill(false)
	return {"elevation": elevation, "cover": cover, "blocked": blocked, "vision_blocked": vision}


static func _ensure_layout_size(arr: Array, default_val: Variant) -> void:
	if arr.size() < 144:
		var old_size := arr.size()
		arr.resize(144)
		for i in range(old_size, 144):
			arr[i] = default_val


static func _get_reserved_positions(room_data: Dictionary) -> Array[Vector2i]:
	var reserved: Array[Vector2i] = []
	if room_data.has("player_start"):
		var ps: Dictionary = room_data["player_start"]
		reserved.append(Vector2i(int(ps.get("x", 0)), int(ps.get("y", 0))))

	if room_data.has("encounters"):
		var encounters: Array = room_data["encounters"]
		for enc: Variant in encounters:
			if enc is Dictionary:
				var positions: Array = enc.get("positions", [])
				for pos_data: Variant in positions:
					if pos_data is Dictionary:
						reserved.append(
							Vector2i(int(pos_data.get("x", 0)), int(pos_data.get("y", 0)))
						)
	return reserved


static func _add_hazard(room_data: Dictionary, x: int, y: int, type: String) -> void:
	if not room_data.has("hazards"):
		room_data["hazards"] = []
	room_data["hazards"].append({"x": x, "y": y, "type": type})
