extends Node
class_name _GameCoordinator

## GameCoordinator
## Manages high-level game flow transitions between Title Screen, Combat, and Sanctum.
## Decouples UI from the underlying state machines.

const COMBAT_ROOM_SCENE := "res://scenes/combat_room.tscn"


## Starts a fresh run.
func cmd_new_game() -> void:
	var run_manager := AutoloadHelper.run_manager()
	if run_manager != null:
		run_manager.cmd_start_run()

	var save_manager := AutoloadHelper.save_manager()
	if save_manager != null:
		save_manager.delete_save()

	_change_scene(COMBAT_ROOM_SCENE)


## Continues a run from the last save.
func cmd_continue_game() -> void:
	var save_manager := AutoloadHelper.save_manager()
	if save_manager == null:
		push_error("GameCoordinator: SaveManager not found.")
		return

	var data := save_manager.load_game()
	if data.is_empty():
		push_warning("GameCoordinator: Attempted to continue but no save found.")
		return

	var run_manager := AutoloadHelper.run_manager()
	if (
		run_manager != null
		and data.has("run_state")
		and typeof(data["run_state"]) == TYPE_DICTIONARY
	):
		run_manager.load_run_state(data["run_state"])
		_change_scene(COMBAT_ROOM_SCENE)
	else:
		push_warning("GameCoordinator: No valid run_state Dictionary found in save data.")
		var tm := AutoloadHelper.toast_manager()
		if tm:
			tm.show_toast("Save File Corrupted!", _ToastManager.ToastType.T_04)


func _change_scene(path: String) -> void:
	if OS.has_feature("headless"):
		var err := get_tree().change_scene_to_file(path)
		if err != OK:
			push_error("GameCoordinator: Failed to change scene to %s" % path)
		return

	var tl: Node = get_node_or_null("/root/TransitionLayer")
	if tl and tl.has_method("fade_out"):
		await tl.fade_out(0.4)

	var tree := get_tree()
	if tree:
		var err := tree.change_scene_to_file(path)
		if err != OK:
			push_error("GameCoordinator: Failed to change scene to %s (Error %d)" % [path, err])

	if tl and tl.has_method("fade_in"):
		await tl.fade_in(0.4)
