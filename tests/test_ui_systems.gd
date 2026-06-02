extends GdUnitTestSuite
## Unit tests for UI systems


func test_toast_system() -> void:
	if OS.has_feature("headless"):
		return
	ToastManager.show_toast("T_01_MESSAGE", ToastManager.ToastType.T_01)
	ToastManager.show_toast("T_02_MESSAGE", ToastManager.ToastType.T_02)


func test_modal_system() -> void:
	if OS.has_feature("headless"):
		return
	var modal_scene: PackedScene = load("res://scenes/ui/modal.tscn") as PackedScene
	var modal: Node = modal_scene.instantiate()
	LayerManager.add_modal(modal)
	if modal.has_method("setup"):
		modal.call("setup", "TEST_MODAL", "THIS_IS_A_TEST")
