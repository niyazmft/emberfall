extends Node


func _ready() -> void:
	if not OS.has_feature("headless"):
		test_toast_system()
		test_modal_system()


func test_toast_system() -> void:
	print("Testing Toast System...")
	ToastManager.show_toast("T_01_MESSAGE", ToastManager.ToastType.T_01)
	ToastManager.show_toast("T_02_MESSAGE", ToastManager.ToastType.T_02)


func test_modal_system() -> void:
	print("Testing Modal System...")
	var modal_scene: PackedScene = load("res://scenes/ui/modal.tscn") as PackedScene
	var modal: Node = modal_scene.instantiate()
	LayerManager.add_modal(modal)
	if modal.has_method("setup"):
		modal.call("setup", "TEST_MODAL", "THIS_IS_A_TEST")
