extends Node
class_name _GameCoordinator

## GameCoordinator
## Manages high-level game flow transitions between Title Screen, Combat, and Sanctum.
## Decouples UI from the underlying state machines.

const COMBAT_ROOM_SCENE := "res://scenes/combat_room.tscn"

var _is_changing_scene: bool = false


## Starts a fresh run.
func cmd_new_game() -> void:
	if _is_changing_scene:
		push_warning("GameCoordinator: Scene change already in progress. Ignoring cmd_new_game.")
		return

	var run_manager := AutoloadHelper.run_manager()
	if run_manager != null:
		run_manager.cmd_start_run()

	var save_manager := AutoloadHelper.save_manager()
	if save_manager != null:
		save_manager.delete_save()

	await _change_scene(COMBAT_ROOM_SCENE)


## Continues a run from the last save.
func cmd_continue_game() -> void:
	if _is_changing_scene:
		push_warning(
			"GameCoordinator: Scene change already in progress. Ignoring cmd_continue_game."
		)
		return

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
		await _change_scene(COMBAT_ROOM_SCENE)
	else:
		push_warning("GameCoordinator: No valid run_state Dictionary found in save data.")
		var tm := AutoloadHelper.toast_manager()
		if tm != null:
			tm.show_toast("Save File Corrupted!", _ToastManager.ToastType.T_04)


func _change_scene(path: String) -> void:
	if _is_changing_scene:
		return
	_is_changing_scene = true

	if OS.has_feature("headless"):
		var tree := get_tree()
		if tree != null:
			var err := tree.change_scene_to_file(path)
			if err != OK:
				push_error("GameCoordinator: Failed to change scene to %s (Error %d)" % [path, err])
				var tm := AutoloadHelper.toast_manager()
				if tm != null:
					tm.show_toast("Failed to load scene.", _ToastManager.ToastType.T_04)
		_is_changing_scene = false
		return

	var tl: _TransitionLayer = get_node_or_null("/root/TransitionLayer") as _TransitionLayer
	if tl != null:
		await tl.fade_out(0.4)

	var tree := get_tree()
	if tree != null:
		var err := tree.change_scene_to_file(path)
		if err != OK:
			push_error("GameCoordinator: Failed to change scene to %s (Error %d)" % [path, err])
			var tm := AutoloadHelper.toast_manager()
			if tm != null:
				tm.show_toast("Failed to load scene.", _ToastManager.ToastType.T_04)

	if tl != null:
		await tl.fade_in(0.4)

	_is_changing_scene = false
