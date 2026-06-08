class_name RoomGenerator
extends Node
## RoomGenerator
## Augments authored room layouts with procedural elements (cover, elevation,
## hazards, blocked tiles) using a deterministic seed and biome templates.

const BIOMES_CONFIG_PATH := "res://config/biomes.json"


## Augments the provided room_data with procedural elements based on biome rules.
static func augmentRoom(roomData: Dictionary, biomeId: String, topologySeed: int) -> void:
	var biomeParams: Dictionary = _getBiomeParams(biomeId)
	if biomeParams.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = topologySeed

	if not roomData.has("layout"):
		roomData["layout"] = _createEmptyLayout()

	var layout: Dictionary = roomData["layout"]
	var elevation: Array = layout.get("elevation", [])
	var cover: Array = layout.get("cover", [])
	var blocked: Array = layout.get("blocked", [])
	var vision: Array = layout.get("vision_blocked", [])

	# Ensure arrays are correct size (144 for 12x12)
	_ensureLayoutSize(elevation, 0)
	_ensureLayoutSize(cover, 0)
	_ensureLayoutSize(blocked, false)
	_ensureLayoutSize(vision, false)

	# Persist fixed arrays back to layout dictionary
	layout["elevation"] = elevation
	layout["cover"] = cover
	layout["blocked"] = blocked
	layout["vision_blocked"] = vision

	var genParams: Dictionary = biomeParams.get("generation_params", {})
	var coverDensity: float = float(genParams.get("cover_density", 0.1))
	var blockedDensity: float = float(genParams.get("blocked_density", 0.05))
	var hazardDensity: float = float(genParams.get("hazard_density", 0.0))
	var hazardTypes: Array = genParams.get("hazard_types", [])
	var elevMin: int = int(genParams.get("elevation_min", 0))
	var elevMax: int = int(genParams.get("elevation_max", 0))

	# Keep track of reserved positions (player start and explicitly placed enemies)
	var reservedPositions: Array[Vector2i] = _getReservedPositions(roomData)

	for i in range(144):
		var x := i % 12
		var y := i / 12
		var pos := Vector2i(x, y)

		if reservedPositions.has(pos):
			continue

		# 1. Blocked Tiles (if not already blocked)
		if not blocked[i] and rng.randf() < blockedDensity:
			blocked[i] = true
			vision[i] = true  # Usually blocked tiles also block vision
			continue  # If blocked, don't place other things

		# 2. Elevation (if currently 0)
		if int(elevation[i]) == 0:
			if rng.randf() < 0.2:  # 20% chance to attempt elevation change
				elevation[i] = rng.randi_range(elevMin, elevMax)

		# 3. Cover (if not blocked and no cover)
		if not blocked[i] and int(cover[i]) == 0:
			if rng.randf() < coverDensity:
				# 70% light cover, 30% heavy cover
				cover[i] = 1 if rng.randf() < 0.7 else 2

		# 4. Hazards
		if rng.randf() < hazardDensity and not hazardTypes.is_empty():
			var hazardType: String = str(hazardTypes[rng.randi() % hazardTypes.size()])
			_addHazard(roomData, x, y, hazardType)


static func _getBiomeParams(biomeId: String) -> Dictionary:
	var f := FileAccess.open(BIOMES_CONFIG_PATH, FileAccess.READ)
	if not f:
		return {}
	var text := f.get_as_text()
	f.close()

	var data_v: Variant = JSON.parse_string(text)
	if not data_v is Dictionary:
		return {}

	var data: Dictionary = data_v as Dictionary
	var biomes_data: Dictionary = data.get("biomes", {}) as Dictionary
	return biomes_data.get(biomeId, {}) as Dictionary


static func _createEmptyLayout() -> Dictionary:
	var elevation: Array = []
	var cover: Array = []
	var blocked: Array = []
	var vision: Array = []
	elevation.resize(144)
	elevation.fill(0)
	cover.resize(144)
	cover.fill(0)
	blocked.resize(144)
	blocked.fill(false)
	vision.resize(144)
	vision.fill(false)
	return {"elevation": elevation, "cover": cover, "blocked": blocked, "vision_blocked": vision}


static func _ensureLayoutSize(arr: Array, defaultVal: Variant) -> void:
	if arr.size() < 144:
		var oldSize: int = arr.size()
		arr.resize(144)
		for i in range(oldSize, 144):
			arr[i] = defaultVal


static func _getReservedPositions(roomData: Dictionary) -> Array[Vector2i]:
	var reserved: Array[Vector2i] = []
	if roomData.has("player_start"):
		var ps: Dictionary = roomData["player_start"] as Dictionary
		reserved.append(Vector2i(int(ps.get("x", 0)), int(ps.get("y", 0))))

	if roomData.has("encounters"):
		var encounters: Array = roomData["encounters"] as Array
		for enc: Variant in encounters:
			if enc is Dictionary:
				var positions: Array = enc.get("positions", []) as Array
				for posData: Variant in positions:
					if posData is Dictionary:
						var d: Dictionary = posData as Dictionary
						reserved.append(Vector2i(int(d.get("x", 0)), int(d.get("y", 0))))
	return reserved


static func _addHazard(roomData: Dictionary, x: int, y: int, type: String) -> void:
	if not roomData.has("hazards"):
		roomData["hazards"] = []
	var hazards: Array = roomData["hazards"] as Array
	hazards.append({"x": x, "y": y, "type": type})
