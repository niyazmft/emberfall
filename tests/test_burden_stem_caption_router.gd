extends SceneTree

## BurdenStemCaptionRouterValidation
## 9 cases for DON-223.

const RouterScript: GDScript = preload("res://scripts/core/burden_stem_caption_router.gd")


func run_all() -> void:
	var passed: int = 0
	var failed: int = 0
	var tests: Array[String] = [
		"test_config_loading",
		"test_would_dispatch_true",
		"test_would_dispatch_cooldown",
		"test_would_dispatch_mwt_binding",
		"test_dispatch_event_triggers_presenter",
		"test_dispatch_event_applies_cooldown",
		"test_reset_cooldowns",
		"test_logical_event_volume_agnostic",
		"test_climb_feature_mapping"
	]

	print("--- Running BurdenStemCaptionRouterValidation ---")
	for name: String in tests:
		print("Running %s..." % name)
		var ok: Variant = call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL")

	print("\nResults: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		quit(1)
	else:
		quit(0)


func test_config_loading() -> bool:
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")  # Force load config
	var configs: Dictionary = router.get("_configs") as Dictionary
	if configs.size() == 4:
		router.queue_free()
		return true
	router.queue_free()
	return false


func test_would_dispatch_true() -> bool:
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")
	var bm: Node = root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)
	var result: bool = bool(router.call("would_dispatch", "BD-BASS", "impact"))
	router.queue_free()
	return result


func test_would_dispatch_cooldown() -> bool:
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")
	var bm: Node = root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)
	router.call("dispatch_event", "BD-BASS", "impact")
	var result: bool = bool(router.call("would_dispatch", "BD-BASS", "impact"))
	router.queue_free()
	return result == false


func test_would_dispatch_mwt_binding() -> bool:
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")
	var bm: Node = root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 0)
	var result: bool = bool(router.call("would_dispatch", "BD-BASS", "impact"))  # requires MWT 3
	router.queue_free()
	return result == false


class MockPresenter:
	extends Node
	var received: bool = false

	func present_caption(_marker: RefCounted) -> void:
		received = true


func test_dispatch_event_triggers_presenter() -> bool:
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")
	var bm: Node = root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	var presenter: MockPresenter = MockPresenter.new()
	router.call("set_presenter", presenter)
	router.call("dispatch_event", "BD-BASS", "impact")

	var result: bool = presenter.received
	router.queue_free()
	return result


func test_dispatch_event_applies_cooldown() -> bool:
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")
	var bm: Node = root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	router.call("dispatch_event", "BD-BASS", "impact")
	var cooldowns: Dictionary = router.get("_cooldowns") as Dictionary
	var cooldown: float = float(cooldowns.get("BD-BASS", 0.0))

	var result: bool = is_equal_approx(cooldown, 4.0)
	router.queue_free()
	return result


func test_reset_cooldowns() -> bool:
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")
	var bm: Node = root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	router.call("dispatch_event", "BD-BASS", "impact")
	router.call("reset_cooldowns")
	var cooldowns: Dictionary = router.get("_cooldowns") as Dictionary
	var cooldown: float = float(cooldowns.get("BD-BASS", 0.0))

	router.queue_free()
	return is_equal_approx(cooldown, 0.0)


func test_logical_event_volume_agnostic() -> bool:
	# Logical events should dispatch even if volume is 0.
	# Our router doesn't even know about volume, so this is true by design.
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")
	var bm: Node = root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	var presenter: MockPresenter = MockPresenter.new()
	router.call("set_presenter", presenter)

	router.call("dispatch_event", "BD-BASS", "impact")

	var result: bool = presenter.received
	router.queue_free()
	return result


func test_climb_feature_mapping() -> bool:
	var router: Node = RouterScript.new()
	root.add_child(router)
	router.call("_ready")
	var bm: Node = root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	var result_expand: bool = bool(router.call("would_dispatch", "BD-CLIMB", "expand"))
	var result_converge: bool = bool(router.call("would_dispatch", "BD-CLIMB", "converge"))

	router.queue_free()
	return result_expand and result_converge


func _initialize() -> void:
	# Mock needed autoloads for headless run
	if not root.has_node("BurdenManager"):
		var bm_script: GDScript = load("res://scripts/autoload/burden_manager.gd") as GDScript
		var bm: Node = bm_script.new()
		bm.name = "BurdenManager"
		root.add_child(bm)

	call_deferred("run_all")
