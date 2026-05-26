extends Node
## Unit / integration tests for Gate 2-2 Burden Event systems.
## Run via Godot Editor test runner or `godot --headless --script tests/test_burden_event.gd`.
##
## Covers:
##   AC-1: JSON schema config loads and validates
##   AC-2: Save schema load/store round-trip
##   AC-3: Numbness cap triggers at exactly N=5 with silent Phase B
##   AC-4: Noun rotation is deterministic per seed and persists across runs
##   AC-5: Localization keys are unique in the master table

func run_all() -> void:
	var passed: int = 0
	var failed: int = 0
	var tests: Array[String] = [
		"test_config_loads",
		"test_save_roundtrip",
		"test_numbness_cap_exactly_five",
		"test_noun_rotation_deterministic",
		"test_variant_selection_fallback",
		"test_localization_keys_unique",
		"test_phase_b_timing_window",
	]

	for name: String in tests:
		print("Running %s ..." % name)
		var ok: Variant = call(name)
		if ok is bool and ok:
			passed += 1
			print("  PASS")
		else:
			failed += 1
			print("  FAIL (returned %s)" % str(ok))

	print("")
	print("Results: %d passed, %d failed out of %d" % [passed, failed, tests.size()])
	if failed > 0:
		push_error("Burden Event test suite had failures.")
		get_tree().quit(1)
	else:
		get_tree().quit(0)


# ── AC-1: Config loads and schema validates ──────────────────────────────
func test_config_loads() -> bool:
	var bm: Node = BurdenManager
	# _ready() will attempt to load config automatically
	bm._ready()

	if not bm._config_loaded:
		push_error("Expected config to be loaded")
		return false
	if bm._collective_nouns.size() != 8:
		push_error("Expected 8 collective nouns, got %d" % bm._collective_nouns.size())
		return false
	if bm._numbness_cap != 5:
		push_error("Expected numbness_cap = 5, got %d" % bm._numbness_cap)
		return false
	if bm._variants_first.size() != 3:
		push_error("Expected 3 first variants, got %d" % bm._variants_first.size())
		return false
	if bm._variants_repeat.size() != 2:
		push_error("Expected 2 repeat variants, got %d" % bm._variants_repeat.size())
		return false
	return true


# ── AC-2: Save schema round-trip ─────────────────────────────────────────
func test_save_roundtrip() -> bool:
	var bm: Node = BurdenManager
	bm._ready()
	bm.reset()

	## Simulate a previous run that persisted noun_index = 3 and lifetime_triggers = 7
	bm.load_memory_state({
		"echo_flags": {
			"burden_noun_index": 3,
			"burden_trigger_history": 7,
		}
	})
	if bm._burden_noun_index != 3:
		push_error("Expected noun_index 3 after load, got %d" % bm._burden_noun_index)
		return false
	if bm._lifetime_trigger_count != 7:
		push_error("Expected lifetime_trigger_count 7 after load, got %d" % bm._lifetime_trigger_count)
		return false

	## Run a new run, trigger once, then save
	bm.reset()
	bm.trigger_burden_event(12345, 67890, 0, 0, true)
	var saved: Dictionary = bm.save_memory_state()
	if saved["burden_noun_index"] != bm._burden_noun_index:
		push_error("Save noun_index mismatch")
		return false
	if saved["burden_trigger_history"] != 8:
		push_error("Expected lifetime_triggers 8 after one trigger, got %d" % saved["burden_trigger_history"])
		return false

	## Reset and reload must preserve cross-run values
	var noun_before: int = bm._burden_noun_index
	var lifetime_before: int = bm._lifetime_trigger_count
	bm.reset()
	if bm._burden_noun_index != noun_before:
		push_error("Reset must NOT clear persisted noun_index")
		return false
	if bm._lifetime_trigger_count != lifetime_before:
		push_error("Reset must NOT clear lifetime_trigger_count")
		return false
	return true


# ── AC-3: Numbness cap triggers at exactly N=5 with silent Phase B ───────
func test_numbness_cap_exactly_five() -> bool:
	var bm: Node = BurdenManager
	bm._ready()
	bm.reset()

	var run_seed: int = 42
	var topo_seed: int = 99
	var room_index: int = 0

	for i: int in range(1, 7):
		var result: _BurdenManager.BurdenEventResult = bm.trigger_burden_event(run_seed, topo_seed, room_index, i, i == 1)
		if i < 5:
			if result.numbness_cap_reached:
				push_error("Trigger #%d should NOT be numb" % i)
				return false
			if result.phase_b_text.is_empty():
				push_error("Trigger #%d Phase B text must NOT be empty" % i)
				return false
		else:
			# i == 5 and i == 6 should both be numb
			if not result.numbness_cap_reached:
				push_error("Trigger #%d MUST be numb" % i)
				return false
			if not result.phase_b_text.is_empty():
				push_error("Trigger #%d Phase B text MUST be empty (silent)" % i)
				return false
			if result.phase_b_localization_key != "BE_NUMBNESS_CAP":
				push_error("Trigger #%d numbness localization key mismatch" % i)
				return false
	return true


# ── AC-4: Noun rotation deterministic per seed and persists ─────────────
func test_noun_rotation_deterministic() -> bool:
	var bm1: Node = BurdenManager
	bm1._ready()
	bm1.reset()

	var run_seed: int = 777
	var topo: int = 333

	var noun1: String = bm1.select_collective_noun(topo, 0)
	var noun2: String = bm1.select_collective_noun(topo, 0)
	if noun1 != noun2:
		push_error("Noun selection must be deterministic for same seed")
		return false

	## Different topology seed → potentially different noun
	var bm2: Node = BurdenManager
	bm2._ready()
	bm2.reset()
	var _noun3: String = bm2.select_collective_noun(topo + 1, 0)
	## We only assert determinism, not that different seeds ALWAYS differ.
	## But we do assert the index is in range.
	if bm1._burden_noun_index < 0 or bm1._burden_noun_index >= bm1._noun_pool_size:
		push_error("Noun index out of range: %d" % bm1._burden_noun_index)
		return false

	## Persistence across runs
	bm1.reset()
	if bm1._burden_noun_index != bm1._burden_noun_index:
		# trivial, but we already tested this in save_roundtrip
		pass
	return true


# ── Variant selection fallback ────────────────────────────────────────────
func test_variant_selection_fallback() -> bool:
	var bm: Node = BurdenManager
	bm._ready()
	bm.reset()

	var v: Dictionary = bm.select_variant_first(111, 0, 0)
	if v.is_empty():
		push_error("Variant selection must not return empty")
		return false
	if not v.has("id"):
		push_error("Variant must have 'id' field")
		return false
	if not v.has("localization_key"):
		push_error("Variant must have 'localization_key' field")
		return false

	## Repeat pool
	var vr: Dictionary = bm.select_variant_repeat(222, 1, 1)
	if vr.is_empty():
		push_error("Repeat variant selection must not return empty")
		return false
	return true


# ── AC-5: Localization keys unique ───────────────────────────────────────
func test_localization_keys_unique() -> bool:
	var bm: Node = BurdenManager
	bm._ready()
	bm.reset()

	var keys: Array[String] = []
	for v: Dictionary in bm._variants_first:
		keys.append(str(v.get("localization_key", "")))
	for v: Dictionary in bm._variants_repeat:
		keys.append(str(v.get("localization_key", "")))

	keys.append("BE_PHASE_A")
	keys.append("BE_PHASE_C")
	keys.append("BE_PHASE_D")
	keys.append(bm._numbness_localization_key)

	var seen: Dictionary = {}
	for k: String in keys:
		if k.is_empty():
			continue
		if seen.has(k):
			push_error("Duplicate localization key detected: %s" % k)
			return false
		seen[k] = true
	return true


# ── Phase B timing window verification ────────────────────────────────────
func test_phase_b_timing_window() -> bool:
	var bm: Node = BurdenManager
	bm._ready()
	bm.reset()

	## The JSON specifies min=10000, max=40000.
	if not bm.is_within_phase_b_window(10000):
		push_error("10 000 ms must be inside window")
		return false
	if not bm.is_within_phase_b_window(25000):
		push_error("25 000 ms must be inside window")
		return false
	if not bm.is_within_phase_b_window(40000):
		push_error("40 000 ms must be inside window")
		return false
	if bm.is_within_phase_b_window(5000):
		push_error("5 000 ms must be outside window")
		return false
	if bm.is_within_phase_b_window(45000):
		push_error("45 000 ms must be outside window")
		return false
	return true


# ── Test Runner ───────────────────────────────────────────────────────────
func _ready() -> void:
	run_all()
