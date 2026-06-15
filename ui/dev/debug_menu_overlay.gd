extends CanvasLayer

## DebugMenuOverlay
## Helper for testing moral weight and burden events.


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_add_moral(1)
		elif event.keycode == KEY_F2:
			_sub_moral(1)
		elif event.keycode == KEY_F3:
			_trigger_test_burden()
		elif event.keycode == KEY_F4:
			simulate_burden_event("BD-BASS", "impact")


func _add_moral(_amount: int) -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm:
		var current: int = bm.total_sentient_kills
		bm.record_sentient_kill("debug_enemy_" + str(current), "Debug Enemy")
		## In a real scenario, entity_lifecycle would call update_moral_weight
		bm.update_moral_weight(current + 1)
		print("Debug: Added moral weight. Current: ", current + 1)


func _sub_moral(amount: int) -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm:
		bm.total_sentient_kills = max(0, bm.total_sentient_kills - amount)
		bm.update_moral_weight(bm.total_sentient_kills)
		print("Debug: Subtracted moral weight. Current: ", bm.total_sentient_kills)


func _trigger_test_burden() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	if bm:
		bm.trigger_burden_event(123, 456, 1, 0, true)
		print("Debug: Triggered test Burden Event")


func simulate_burden_event(stem_id: String, event_id: String) -> void:
	var am: _AudioMiddleware = AutoloadHelper.audio_middleware()
	if am:
		var router: Node = am.get_stem_router()
		if router:
			router.call("dispatch_event", stem_id, event_id)
			print("Debug: Simulated burden event %s/%s" % [stem_id, event_id])
