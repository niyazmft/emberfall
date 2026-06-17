extends GdUnitTestSuite
## Unit tests for UI systems


func test_toast_system() -> void:
	if OS.has_feature("headless"):
		return
	var tm := AutoloadHelper.toast_manager()
	if tm:
		tm.show_toast("T_01_MESSAGE", _ToastManager.ToastType.T_01)
		tm.show_toast("T_02_MESSAGE", _ToastManager.ToastType.T_02)


func test_modal_system() -> void:
	if OS.has_feature("headless"):
		return
	var lm := AutoloadHelper.layer_manager()
	var modal_scene: PackedScene = load("res://scenes/ui/modal.tscn") as PackedScene
	var modal: Node = modal_scene.instantiate()
	if lm:
		lm.add_modal(modal)
	if modal.has_method("setup"):
		modal.call("setup", "TEST_MODAL", "THIS_IS_A_TEST")
