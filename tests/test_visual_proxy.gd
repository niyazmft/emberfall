extends GdUnitTestSuite


func test_visual_proxy() -> void:
	# Load classes manually to avoid parse errors in headless environment
	var EntityClass: GDScript = load("res://scripts/entities/entity.gd")
	var EntityVisualProxyClass: GDScript = load("res://scripts/visual/entity_visual_proxy.gd")

	# Mock GridRenderer since we are in a headless test environment without a full scene tree
	var grid_renderer: Node2D = load("res://scripts/visual/grid_renderer.gd").new()
	grid_renderer.name = "GridRenderer"

	var combat_room: Node2D = auto_free(Node2D.new())
	combat_room.name = "CombatRoom"
	add_child(combat_room)
	combat_room.add_child(grid_renderer)

	# 1. Test Setup
	var entity: Resource = EntityClass.new("TestEntity", 1, 1, 10, 5, 5, 1, 0, 0)
	var proxy: Node2D = EntityVisualProxyClass.new()
	proxy.set("entity", entity)
	combat_room.add_child(proxy)

	# Wait for ready (one frame)
	await get_tree().process_frame

	# 2. Verify Initial Sync
	var expected_pos: Vector2 = grid_renderer.call("grid_to_world", 1, 1, 0)
	var actual_pos: Vector2 = proxy.get("_target_position")
	assert_that(actual_pos).is_equal(expected_pos)

	# 3. Verify Position Change
	entity.set("x", 2)
	entity.set("y", 3)
	expected_pos = grid_renderer.call("grid_to_world", 2, 3, 0)
	actual_pos = proxy.get("_target_position")
	assert_that(actual_pos).is_equal(expected_pos)

	# 4. Verify Elevation Change
	entity.set("elevation", 2)
	expected_pos = grid_renderer.call("grid_to_world", 2, 3, 2)
	actual_pos = proxy.get("_target_position")
	assert_that(actual_pos).is_equal(expected_pos)

	var shadow_sprite: Sprite2D = proxy.get("shadow_sprite")
	assert_that(shadow_sprite.position.y).is_equal(32.0)

	var height_indicator: CanvasItem = proxy.get("height_indicator")
	assert_that(height_indicator.visible).is_true()

	# 5. Verify Facing Change
	entity.set("facing_x", -1)
	var base_sprite: Sprite2D = proxy.get("base_sprite")
	assert_that(base_sprite.flip_h).is_true()

	entity.set("facing_x", 1)
	assert_that(base_sprite.flip_h).is_false()

	# 6. Verify State Change
	entity.set("state", 2)  # Entity.State.DYING = 2
	assert_that(proxy.modulate).is_equal(Color(1.0, 0.4, 0.4))

	# 7. Verify Damage Signal -> Apparition Effect
	var app_mock := Node2D.new()
	app_mock.name = "ApparitionRenderer"
	var app_script := GDScript.new()
	app_script.source_code = """
extends Node2D
var damage_triggered := false
func trigger_damage_effect() -> void:
	damage_triggered = true
"""
	app_script.reload()
	app_mock.set_script(app_script)
	proxy.add_child(app_mock)

	entity.set("hp", 5)  # Damage from 10 to 5
	assert_that(app_mock.get("damage_triggered")).is_true()

	# 8. Verify Hit Flash Weight
	# The weight starts at 1.0 on hit.
	# Since it's a tween, we might need to check immediately or wait a frame.
	var hit_weight: float = proxy.get("_hit_flash_weight")
	assert_that(hit_weight > 0.0).is_true()

	# Verify shader parameter on base_sprite
	var material: ShaderMaterial = base_sprite.material as ShaderMaterial
	assert_that(material).is_not_null()
	var shaderWeight: float = material.get_shader_parameter("u_hit_flash")
	assert_that(shaderWeight).is_equal(hitWeight)
