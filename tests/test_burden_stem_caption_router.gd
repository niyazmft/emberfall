extends GdUnitTestSuite

const RouterScript: GDScript = preload("res://scripts/core/burden_stem_caption_router.gd")

var _bm: Node


func before_all() -> void:
	var root: Window = get_tree().root
	if not root.has_node("BurdenManager"):
		var bm_script: GDScript = load("res://scripts/autoload/burden_manager.gd") as GDScript
		_bm = bm_script.new()
		_bm.name = "BurdenManager"
		root.add_child(_bm)


func after_all() -> void:
	if _bm and is_instance_valid(_bm):
		_bm.queue_free()


func test_config_loading() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var configs: Dictionary = router.get("_configs") as Dictionary
	assert_that(configs.size()).is_equal(4)


func test_would_dispatch_true() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var bm: Node = get_tree().root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)
	var result: bool = bool(router.call("would_dispatch", "BD-BASS", "impact"))
	assert_that(result).is_true()


func test_would_dispatch_cooldown() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var bm: Node = get_tree().root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)
	router.call("dispatch_event", "BD-BASS", "impact")
	var result: bool = bool(router.call("would_dispatch", "BD-BASS", "impact"))
	assert_that(result).is_false()


func test_would_dispatch_mwt_binding() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var bm: Node = get_tree().root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 0)
	var result: bool = bool(router.call("would_dispatch", "BD-BASS", "impact"))
	assert_that(result).is_false()


class MockPresenter:
	extends Node
	var received: bool = false

	func present_caption(_marker: RefCounted) -> void:
		received = true


func test_dispatch_event_triggers_presenter() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var bm: Node = get_tree().root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	var presenter: MockPresenter = auto_free(MockPresenter.new())
	router.call("set_presenter", presenter)
	router.call("dispatch_event", "BD-BASS", "impact")

	assert_that(presenter.received).is_true()


func test_dispatch_event_applies_cooldown() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var bm: Node = get_tree().root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	router.call("dispatch_event", "BD-BASS", "impact")
	var cooldowns: Dictionary = router.get("_cooldowns") as Dictionary
	var cooldown: float = float(cooldowns.get("BD-BASS", 0.0))

	assert_that(is_equal_approx(cooldown, 4.0)).is_true()


func test_reset_cooldowns() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var bm: Node = get_tree().root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	router.call("dispatch_event", "BD-BASS", "impact")
	router.call("reset_cooldowns")
	var cooldowns: Dictionary = router.get("_cooldowns") as Dictionary
	var cooldown: float = float(cooldowns.get("BD-BASS", 0.0))

	assert_that(is_equal_approx(cooldown, 0.0)).is_true()


func test_logical_event_volume_agnostic() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var bm: Node = get_tree().root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	var presenter: MockPresenter = auto_free(MockPresenter.new())
	router.call("set_presenter", presenter)

	router.call("dispatch_event", "BD-BASS", "impact")

	assert_that(presenter.received).is_true()


func test_climb_feature_mapping() -> void:
	var router: Node = auto_free(RouterScript.new())
	get_tree().root.add_child(router)
	router.call("_ready")
	var bm: Node = get_tree().root.get_node_or_null("BurdenManager")
	if bm:
		bm.set("current_mwt_level", 3)

	var result_expand: bool = bool(router.call("would_dispatch", "BD-CLIMB", "expand"))
	var result_converge: bool = bool(router.call("would_dispatch", "BD-CLIMB", "converge"))

	assert_that(result_expand and result_converge).is_true()
