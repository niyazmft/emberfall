extends Node
class_name _GameCoordinator

## GameCoordinator
## Centralizes high-level game flow commands (New Game, Continue, etc.)
## Reuses logic from RunManager and SaveManager to ensure consistency.

const COMBAT_ROOM_SCENE: String = "res://scenes/combat_room.tscn"


## Starts a fresh run: resets RunManager, deletes old mid-run save, and transitions.
func cmd_new_game() -> void:
	_print_debug("cmd_new_game() triggered")

	var run_manager: _RunManager = AutoloadHelper.run_manager()
	if run_manager != null:
		run_manager.cmd_start_run()

		# Delete existing save so Continue doesn't re-offer it on a fresh run
		var save_manager: _SaveManager = AutoloadHelper.save_manager()
		if save_manager != null:
			save_manager.delete_save()

	get_tree().change_scene_to_file(COMBAT_ROOM_SCENE)


## Resumes a saved run: loads state from SaveManager into RunManager and transitions.
func cmd_continue_game() -> void:
	_print_debug("cmd_continue_game() triggered")

	var save_manager: _SaveManager = AutoloadHelper.save_manager()
	if save_manager == null:
		push_error("GameCoordinator: SaveManager not available for Continue.")
		return

	var data: Dictionary = save_manager.load_game()
	if data.is_empty():
		var tm: _ToastManager = AutoloadHelper.toast_manager()
		if tm:
			tm.show_toast("error.save.not_found", _ToastManager.ToastType.T_04)
		push_warning("GameCoordinator: Continue pressed but no valid save found.")
		return

	var run_manager: _RunManager = AutoloadHelper.run_manager()
	if run_manager != null and data.has("run_state"):
		run_manager.load_run_state(data["run_state"] as Dictionary)
		get_tree().change_scene_to_file(COMBAT_ROOM_SCENE)
	else:
		var tm: _ToastManager = AutoloadHelper.toast_manager()
		if tm:
			tm.show_toast("error.save.corrupted", _ToastManager.ToastType.T_04)
		push_warning("GameCoordinator: No run_state in save data or RunManager missing.")


func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("[GameCoordinator] %s" % msg)
