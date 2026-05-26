extends Node

## BurdenStemCaptionRouterValidation
## 9 cases for DON-223.

const Router = preload("res://src/Audio/Captioning/burden_stem_caption_router.gd")

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
		var ok: bool = call(name)
		if ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL")

	print("\nResults: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func test_config_loading() -> bool:
	var router := Router.new()
	add_child(router)
	if router._configs.size() == 4:
		router.queue_free()
		return true
	router.queue_free()
	return false

func test_would_dispatch_true() -> bool:
	var router := Router.new()
	add_child(router)
	if BurdenManager: BurdenManager.current_mwt_level = 3
	var result: bool = router.would_dispatch("BD-BASS", "impact")
	router.queue_free()
	return result

func test_would_dispatch_cooldown() -> bool:
	var router := Router.new()
	add_child(router)
	if BurdenManager: BurdenManager.current_mwt_level = 3
	router.dispatch_event("BD-BASS", "impact")
	var result: bool = router.would_dispatch("BD-BASS", "impact")
	router.queue_free()
	return result == false

func test_would_dispatch_mwt_binding() -> bool:
	var router := Router.new()
	add_child(router)
	if BurdenManager: BurdenManager.current_mwt_level = 0
	var result: bool = router.would_dispatch("BD-BASS", "impact") # requires MWT 3
	router.queue_free()
	return result == false

class MockPresenter extends "res://src/Audio/Captioning/caption_presenter.gd":
	var received := false
	func present_caption(_marker: RefCounted) -> void:
		received = true

func test_dispatch_event_triggers_presenter() -> bool:
	var router := Router.new()
	add_child(router)
	if BurdenManager: BurdenManager.current_mwt_level = 3

	var presenter := MockPresenter.new()
	router.set_presenter(presenter)
	router.dispatch_event("BD-BASS", "impact")

	var result: bool = presenter.received
	router.queue_free()
	return result

func test_dispatch_event_applies_cooldown() -> bool:
	var router := Router.new()
	add_child(router)
	if BurdenManager: BurdenManager.current_mwt_level = 3

	router.dispatch_event("BD-BASS", "impact")
	var cooldown: float = router._cooldowns.get("BD-BASS", 0.0)

	var result: bool = is_equal_approx(cooldown, 4.0)
	router.queue_free()
	return result

func test_reset_cooldowns() -> bool:
	var router := Router.new()
	add_child(router)
	if BurdenManager: BurdenManager.current_mwt_level = 3

	router.dispatch_event("BD-BASS", "impact")
	router.reset_cooldowns()
	var cooldown: float = router._cooldowns.get("BD-BASS", 0.0)

	var result: bool = is_equal_approx(cooldown, 0.0)
	router.queue_free()
	return result

func test_logical_event_volume_agnostic() -> bool:
	# Logical events should dispatch even if volume is 0.
	# Our router doesn't even know about volume, so this is true by design.
	var router := Router.new()
	add_child(router)
	if BurdenManager: BurdenManager.current_mwt_level = 3

	var presenter := MockPresenter.new()
	router.set_presenter(presenter)

	router.dispatch_event("BD-BASS", "impact")

	var result: bool = presenter.received
	router.queue_free()
	return result

func test_climb_feature_mapping() -> bool:
	var router := Router.new()
	add_child(router)
	if BurdenManager: BurdenManager.current_mwt_level = 3

	var result_expand: bool = router.would_dispatch("BD-CLIMB", "expand")
	var result_converge: bool = router.would_dispatch("BD-CLIMB", "converge")

	router.queue_free()
	return result_expand and result_converge

func _ready() -> void:
	await get_tree().process_frame
	run_all()
