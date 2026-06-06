extends GdUnitTestSuite

func test_codex_manager_initialization() -> void:
	var cm: Node = AutoloadHelper.codex_manager()
	assert_that(cm).is_not_null()

	# Check if data was loaded
	assert_int(cm.get_all_bios().size()).is_greater_equal(1)
	assert_int(cm.get_all_codex_entries().size()).is_greater_equal(1)
	assert_int(cm.get_all_legacy_entries().size()).is_greater_equal(1)

func test_codex_unlock_logic() -> void:
	var cm: Node = AutoloadHelper.codex_manager()

	# Test default unlock
	assert_bool(cm.is_unlocked("KEEPER")).is_true()
	assert_bool(cm.is_unlocked("GRUNT")).is_false()

	# Test manual unlock
	cm.unlock("GRUNT")
	assert_bool(cm.is_unlocked("GRUNT")).is_true()

func test_save_integration() -> void:
	var cm: Node = AutoloadHelper.codex_manager()

	cm.unlock("ARCHER")
	var save_data: Dictionary = cm.get_save_data()
	assert_bool(save_data.get("ARCHER", false)).is_true()

	# Simulate save/load cycle (partial)
	var full_save_state := {
		"memory_state": {
			"echo_flags": {
				"narrative_unlocks": {
					"TANK": true
				}
			}
		}
	}

	# Directly call the handler to simulate load
	cm._on_save_load_completed(full_save_state)
	assert_bool(cm.is_unlocked("TANK")).is_true()
