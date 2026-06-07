class_name QAActionExecutor
extends RefCounted
## Executes actions returned by the AI, supporting both simulated input and direct API calls.
##
## Simulated input actions (prefixed with `input_`) feed events through Godot's Input
## system so the full UI pipeline is exercised.
## Direct API actions (prefixed with `api_`) call autoload methods directly for fast,
## deterministic validation.
##
## Usage:
##   var executor := QAActionExecutor.new()
##   executor.execute({"type": "input_click", "x": 960, "y": 540})
##   executor.execute({"type": "api_move_entity", "entity_id": "keeper", "x": 3, "y": 4})

const CLICK_DURATION_MS: int = 100

## Emitted after every action so the runner can log or screenshot.
signal action_executed(action: Dictionary, result: Dictionary)


## Main dispatch. Returns a result Dictionary with at least {"success": bool}.
func execute(action: Dictionary) -> Dictionary:
	var action_type: String = str(action.get("type", ""))
	if action_type.is_empty():
		return {"success": false, "error": "Missing action type"}

	var result: Dictionary
	if action_type.begins_with("input_"):
		result = _execute_input(action)
	elif action_type.begins_with("api_"):
		result = _execute_api(action)
	else:
		result = {"success": false, "error": "Unknown action type: " + action_type}

	action_executed.emit(action, result)
	return result


# ═══════════════════════════════════════════════════════════════════════════════
# Simulated Input Actions
# ═══════════════════════════════════════════════════════════════════════════════

func _execute_input(action: Dictionary) -> Dictionary:
	var action_type: String = str(action.get("type", ""))
	match action_type:
		"input_click":
			return _input_click(action)
		"input_double_click":
			return _input_double_click(action)
		"input_drag":
			return _input_drag(action)
		"input_key":
			return _input_key(action)
		"input_text":
			return _input_text(action)
		"input_wait":
			return _input_wait(action)
		_:
			return {"success": false, "error": "Unknown input action: " + action_type}


func _input_click(action: Dictionary) -> Dictionary:
	var x: int = int(action.get("x", 0))
	var y: int = int(action.get("y", 0))
	var button: int = int(action.get("button", MOUSE_BUTTON_LEFT))

	var press := InputEventMouseButton.new()
	press.button_index = button
	press.position = Vector2(x, y)
	press.pressed = true
	Input.parse_input_event(press)

	await _delay_ms(CLICK_DURATION_MS)

	var release := InputEventMouseButton.new()
	release.button_index = button
	release.position = Vector2(x, y)
	release.pressed = false
	Input.parse_input_event(release)

	return {"success": true, "x": x, "y": y}


func _input_double_click(action: Dictionary) -> Dictionary:
	var x: int = int(action.get("x", 0))
	var y: int = int(action.get("y", 0))
	var button: int = int(action.get("button", MOUSE_BUTTON_LEFT))

	for i: int in range(2):
		var press := InputEventMouseButton.new()
		press.button_index = button
		press.position = Vector2(x, y)
		press.pressed = true
		press.double_click = (i == 1)
		Input.parse_input_event(press)

		await _delay_ms(CLICK_DURATION_MS)

		var release := InputEventMouseButton.new()
		release.button_index = button
		release.position = Vector2(x, y)
		release.pressed = false
		Input.parse_input_event(release)

		if i == 0:
			await _delay_ms(CLICK_DURATION_MS)

	return {"success": true, "x": x, "y": y}


func _input_drag(action: Dictionary) -> Dictionary:
	var from_x: int = int(action.get("from_x", 0))
	var from_y: int = int(action.get("from_y", 0))
	var to_x: int = int(action.get("to_x", 0))
	var to_y: int = int(action.get("to_y", 0))
	var button: int = int(action.get("button", MOUSE_BUTTON_LEFT))
	var steps: int = int(action.get("steps", 10))

	var press := InputEventMouseButton.new()
	press.button_index = button
	press.position = Vector2(from_x, from_y)
	press.pressed = true
	Input.parse_input_event(press)

	for i: int in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var mx: int = int(lerp(float(from_x), float(to_x), t))
		var my: int = int(lerp(float(from_y), float(to_y), t))
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(mx, my)
		motion.relative = Vector2(
			float(to_x - from_x) / float(steps),
			float(to_y - from_y) / float(steps)
		)
		Input.parse_input_event(motion)
		await _delay_ms(16)

	var release := InputEventMouseButton.new()
	release.button_index = button
	release.position = Vector2(to_x, to_y)
	release.pressed = false
	Input.parse_input_event(release)

	return {"success": true, "from": Vector2(from_x, from_y), "to": Vector2(to_x, to_y)}


func _input_key(action: Dictionary) -> Dictionary:
	var key_str: String = str(action.get("key", ""))
	var pressed: bool = bool(action.get("pressed", true))

	var keycode: Key = OS.find_keycode_from_string(key_str)
	if keycode == KEY_NONE:
		return {"success": false, "error": "Unknown key: " + key_str}

	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = pressed
	Input.parse_input_event(ev)

	return {"success": true, "key": key_str, "pressed": pressed}


func _input_text(action: Dictionary) -> Dictionary:
	var text: String = str(action.get("text", ""))
	for c: String in text:
		var ev := InputEventKey.new()
		ev.unicode = c.unicode_at(0)
		ev.pressed = true
		Input.parse_input_event(ev)
		ev = InputEventKey.new()
		ev.unicode = c.unicode_at(0)
		ev.pressed = false
		Input.parse_input_event(ev)
	return {"success": true, "text": text}


func _input_wait(action: Dictionary) -> Dictionary:
	var ms: int = int(action.get("ms", 1000))
	await _delay_ms(ms)
	return {"success": true, "waited_ms": ms}


# ═══════════════════════════════════════════════════════════════════════════════
# Direct API Actions
# ═══════════════════════════════════════════════════════════════════════════════

func _execute_api(action: Dictionary) -> Dictionary:
	var action_type: String = str(action.get("type", ""))
	match action_type:
		"api_move_entity":
			return _api_move_entity(action)
		"api_apply_damage":
			return _api_apply_damage(action)
		"api_start_run":
			return _api_start_run(action)
		"api_transition_run_state":
			return _api_transition_run_state(action)
		"api_click_ui_by_text":
			return _api_click_ui_by_text(action)
		"api_set_locale":
			return _api_set_locale(action)
		_:
			return {"success": false, "error": "Unknown API action: " + action_type}


func _api_move_entity(action: Dictionary) -> Dictionary:
	var x: int = int(action.get("x", -1))
	var y: int = int(action.get("y", -1))
	var entity_id: String = str(action.get("entity_id", ""))
	if x < 0 or y < 0:
		return {"success": false, "error": "Invalid coordinates"}

	var gs: _GridSystem = AutoloadHelper.grid_system()
	if gs == null:
		return {"success": false, "error": "GridSystem not available"}
	if not gs.is_in_bounds(x, y):
		return {"success": false, "error": "Out of bounds"}

	## Note: This is a direct API call that bypasses normal gameplay input.
	## In a real integration, the caller would need to resolve entity_id
	## to an actual Entity instance and call the appropriate lifecycle method.
	## Here we return success to indicate the grid can accept the move.
	return {
		"success": gs.can_move(0, 0, x, y),
		"target_tile": {"x": x, "y": y},
		"entity_id": entity_id
	}


func _api_apply_damage(action: Dictionary) -> Dictionary:
	var amount: int = int(action.get("amount", 0))
	var entity_id: String = str(action.get("entity_id", ""))
	var el: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if el == null:
		return {"success": false, "error": "EntityLifecycle not available"}
	## Direct API placeholder: in a full integration this would resolve
	## entity_id to an Entity and call el.apply_damage(entity, amount).
	return {"success": true, "amount": amount, "entity_id": entity_id}


func _api_start_run(action: Dictionary) -> Dictionary:
	var rm: _RunManager = AutoloadHelper.run_manager()
	if rm == null:
		return {"success": false, "error": "RunManager not available"}
	if rm.has_method("cmd_start_run"):
		rm.call("cmd_start_run")
		return {"success": true}
	return {"success": false, "error": "cmd_start_run not found on RunManager"}


func _api_transition_run_state(action: Dictionary) -> Dictionary:
	var state_name: String = str(action.get("state", ""))
	var rm: _RunManager = AutoloadHelper.run_manager()
	if rm == null:
		return {"success": false, "error": "RunManager not available"}
	if rm.has_method("transition_to"):
		rm.call("transition_to", state_name)
		return {"success": true, "state": state_name}
	return {"success": false, "error": "transition_to not found on RunManager"}


func _api_click_ui_by_text(action: Dictionary) -> Dictionary:
	var text: String = str(action.get("text", ""))
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return {"success": false, "error": "No SceneTree"}
	var found: Control = _find_control_by_text(tree.root, text)
	if found == null:
		return {"success": false, "error": "No UI control with text: " + text}
	var gpos: Vector2 = found.get_global_position()
	var size: Vector2 = found.get_size()
	var center: Vector2 = gpos + size / 2.0
	return await execute({
		"type": "input_click",
		"x": int(center.x),
		"y": int(center.y)
	})


func _api_set_locale(action: Dictionary) -> Dictionary:
	var locale: String = str(action.get("locale", "en"))
	var lm: Node = AutoloadHelper.localization_manager()
	if lm == null:
		return {"success": false, "error": "LocalizationManager not available"}
	if lm.has_method("set_locale"):
		lm.call("set_locale", locale)
		return {"success": true, "locale": locale}
	return {"success": false, "error": "set_locale not found on LocalizationManager"}


func _find_control_by_text(node: Node, text: String) -> Control:
	if node is Control:
		var c: Control = node as Control
		if c is Button or c is Label or c is LinkButton or c is MenuButton:
			var label: String = ""
			if c.has_method("get_text"):
				label = str(c.call("get_text"))
			elif c.has_method("get_title"):
				label = str(c.call("get_title"))
			if label.findn(text) >= 0:
				return c
	for child: Node in node.get_children():
		var result: Control = _find_control_by_text(child, text)
		if result != null:
			return result
	return null


func _delay_ms(ms: int) -> void:
	await Engine.get_main_loop().create_timer(float(ms) / 1000.0).timeout
