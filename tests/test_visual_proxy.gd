extends SceneTree


func _init() -> void:
	print("--- Running EntityVisualProxy Tests ---")

	# Load classes manually to avoid parse errors in headless environment
	var EntityClass: GDScript = load("res://scripts/entities/entity.gd")
	var EntityVisualProxyClass: GDScript = load("res://scripts/visual/entity_visual_proxy.gd")

	# Mock GridRenderer since we are in a headless test environment without a full scene tree
	var grid_renderer := Node2D.new()
	grid_renderer.name = "GridRenderer"
	# Standard 2:1 isometric formula as in grid_renderer.gd
	var script := GDScript.new()
	script.source_code = "extends Node2D\nfunc grid_to_world(x: int, y: int, elevation: int) -> Vector2:\n\treturn Vector2((float(x) - float(y)) * 32, (float(x) + float(y)) * 16 - float(elevation) * 16)\n"
	script.reload()
	grid_renderer.set_script(script)

	var root: Window = get_root()
	var combat_room := Node2D.new()
	combat_room.name = "CombatRoom"
	root.add_child(combat_room)
	combat_room.add_child(grid_renderer)

	# 1. Test Setup
	var entity: Resource = EntityClass.new("TestEntity", 1, 1, 10, 5, 5, 1, 0, 0)
	var proxy: Node2D = EntityVisualProxyClass.new()
	proxy.set("entity", entity)
	combat_room.add_child(proxy)

	# Wait for ready (one frame)
	await process_frame

	# 2. Verify Initial Sync
	var expected_pos: Vector2 = grid_renderer.call("grid_to_world", 1, 1, 0)
	var actual_pos: Vector2 = proxy.get("_target_position")
	print("Expected pos: ", expected_pos, " Actual pos: ", actual_pos)
	assert(actual_pos == expected_pos, "Initial target position mismatch")
	print("[PASS] Initial sync correct")

	# 3. Verify Position Change
	entity.set("x", 2)
	entity.set("y", 3)
	expected_pos = grid_renderer.call("grid_to_world", 2, 3, 0)
	actual_pos = proxy.get("_target_position")
	print("Expected pos: ", expected_pos, " Actual pos: ", actual_pos)
	assert(actual_pos == expected_pos, "Position change target mismatch")
	print("[PASS] Position change correctly updates target")

	# 4. Verify Elevation Change
	entity.set("elevation", 2)
	expected_pos = grid_renderer.call("grid_to_world", 2, 3, 2)
	actual_pos = proxy.get("_target_position")
	print("Expected pos: ", expected_pos, " Actual pos: ", actual_pos)
	assert(actual_pos == expected_pos, "Elevation change target mismatch")
	var shadow_sprite: Sprite2D = proxy.get("shadow_sprite")
	assert(shadow_sprite.position.y == 32.0, "Shadow offset mismatch at elevation 2")
	var height_indicator: CanvasItem = proxy.get("height_indicator")
	assert(height_indicator.visible == true, "Height indicator should be visible")
	print("[PASS] Elevation change correctly updates target and visuals")

	# 5. Verify Facing Change
	entity.set("facing_x", -1)
	var base_sprite: Sprite2D = proxy.get("base_sprite")
	assert(base_sprite.flip_h == true, "Base sprite should be flipped for negative facing_x")
	entity.set("facing_x", 1)
	assert(base_sprite.flip_h == false, "Base sprite should not be flipped for positive facing_x")
	print("[PASS] Facing change correctly updates sprite flip")

	# 6. Verify State Change
	entity.set("state", 2)  # Entity.State.DYING = 2
	assert(proxy.modulate == Color(1.0, 0.4, 0.4), "Modulate mismatch for DYING state")
	print("[PASS] State change correctly updates modulation")

	# 7. Verify Damage Signal -> Apparition Effect
	var app_mock := Node2D.new()
	app_mock.name = "ApparitionRenderer"
	var app_script := GDScript.new()
	app_script.source_code = "extends Node2D\nvar damage_triggered := false\nfunc trigger_damage_effect() -> void:\n\tdamage_triggered = true\n"
	app_script.reload()
	app_mock.set_script(app_script)
	proxy.add_child(app_mock)

	entity.set("hp", 5)  # Damage from 10 to 5
	assert(
		app_mock.get("damage_triggered") == true,
		"Damage effect should have been triggered on ApparitionRenderer"
	)
	print("[PASS] Damage signal correctly triggers apparition effect")

	print("--- All EntityVisualProxy Tests Passed ---")
	quit()
