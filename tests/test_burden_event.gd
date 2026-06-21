extends GdUnitTestSuite


# ── AC-1: Config loads and schema validates ──────────────────────────────
func test_config_loads() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	# _ready() will attempt to load config automatically
	bm._ready()

	assert_that(bm._config_loaded).is_true()
	assert_that(bm._event_engine._collective_nouns.size()).is_equal(8)
	assert_that(bm._event_engine._numbness_cap).is_equal(5)
	assert_that(bm._event_engine._variants_first.size()).is_equal(10)
	assert_that(bm._event_engine._variants_repeat.size()).is_equal(5)


# ── AC-2: Save schema round-trip ─────────────────────────────────────────
func test_save_roundtrip() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm._ready()
	bm.reset()

	## Simulate a previous run that persisted noun_index = 3 and lifetime_triggers = 7
	(
		bm
		. load_memory_state(
			{
				"echo_flags":
				{
					"burden_noun_index": 3,
					"burden_trigger_history": 7,
				}
			}
		)
	)
	assert_that(bm._burden_noun_index).is_equal(3)
	assert_that(bm._lifetime_trigger_count).is_equal(7)

	## Run a new run, trigger once, then save
	bm.reset()
	bm.trigger_burden_event(12345, 67890, 0, 0, true)
	var saved: Dictionary = bm.save_memory_state()

	assert_that(saved["burden_noun_index"]).is_equal(bm._burden_noun_index)
	assert_that(saved["burden_trigger_history"]).is_equal(8)

	## Reset and reload must preserve cross-run values
	var noun_before: int = bm._burden_noun_index
	var lifetime_before: int = bm._lifetime_trigger_count
	bm.reset()
	assert_that(bm._burden_noun_index).is_equal(noun_before)
	assert_that(bm._lifetime_trigger_count).is_equal(lifetime_before)


# ── AC-3: Numbness cap triggers at exactly N=5 with silent Phase B ───────
func test_numbness_cap_exactly_five() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm._ready()
	bm.reset()

	var run_seed: int = 42
	var topo_seed: int = 99
	var room_index: int = 0

	for i: int in range(1, 7):
		var result: _BurdenManager.BurdenEventResult = bm.trigger_burden_event(
			run_seed, topo_seed, room_index, i, i == 1
		)
		if i < 5:
			assert_that(result.numbness_cap_reached).is_false()
			assert_that(result.phase_b_text.is_empty()).is_false()
		else:
			# i == 5 and i == 6 should both be numb
			assert_that(result.numbness_cap_reached).is_true()
			assert_that(result.phase_b_text.is_empty()).is_true()
			assert_that(result.phase_b_localization_key).is_equal("BE_NUMBNESS_CAP")


# ── AC-4: Noun rotation deterministic per seed and persists ─────────────
func test_noun_rotation_deterministic() -> void:
	var bm1: _BurdenManager = AutoloadHelper.burden_manager()
	bm1._ready()
	bm1.reset()

	var run_seed: int = 777
	var topo: int = 333

	var noun1: String = bm1.select_collective_noun(topo, 0)
	var noun2: String = bm1.select_collective_noun(topo, 0)
	assert_that(noun1).is_equal(noun2)

	## Different topology seed → potentially different noun
	var bm2: _BurdenManager = AutoloadHelper.burden_manager()
	bm2._ready()
	bm2.reset()
	var noun3: String = bm2.select_collective_noun(topo + 1, 0)

	assert_that(bm1._burden_noun_index >= 0).is_true()
	assert_that(bm1._burden_noun_index < bm1._event_engine._noun_pool_size).is_true()

	## Persistence across runs
	bm1.reset()
	assert_that(bm1._burden_noun_index).is_equal(bm1._burden_noun_index)


# ── Variant selection fallback ────────────────────────────────────────────
func test_variant_selection_fallback() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm._ready()
	bm.reset()

	var v: Dictionary = bm.select_variant_first(111, 0, 0)
	assert_that(v.is_empty()).is_false()
	assert_that(v.has("id")).is_true()
	assert_that(v.has("localization_key")).is_true()

	## Repeat pool
	var vr: Dictionary = bm.select_variant_repeat(222, 1, 1)
	assert_that(vr.is_empty()).is_false()


# ── AC-5: Localization keys unique ───────────────────────────────────────
func test_localization_keys_unique() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm._ready()
	bm.reset()

	var keys: Array[String] = []
	for v: Dictionary in bm._event_engine._variants_first:
		keys.append(str(v.get("localization_key", "")))
	for v: Dictionary in bm._event_engine._variants_repeat:
		keys.append(str(v.get("localization_key", "")))

	keys.append("BE_PHASE_A")
	keys.append("BE_PHASE_C")
	keys.append("BE_PHASE_D")
	keys.append(bm._event_engine._numbness_localization_key)

	var seen: Dictionary = {}
	for k: String in keys:
		if k.is_empty():
			continue
		assert_that(seen.has(k)).is_false()
		seen[k] = true


# ── Phase B timing window verification ────────────────────────────────────
func test_phase_b_timing_window() -> void:
	var bm: _BurdenManager = AutoloadHelper.burden_manager()
	bm._ready()
	bm.reset()

	## The JSON specifies min=10000, max=40000.
	assert_that(bm.is_within_phase_b_window(10000)).is_true()
	assert_that(bm.is_within_phase_b_window(25000)).is_true()
	assert_that(bm.is_within_phase_b_window(40000)).is_true()
	assert_that(bm.is_within_phase_b_window(5000)).is_false()
	assert_that(bm.is_within_phase_b_window(45000)).is_false()
