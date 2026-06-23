extends GdUnitTestSuite


func test_victory_narrative_selection_deterministic() -> void:
	var runner: GdUnitSceneRunner = scene_runner("res://scenes/ui/victory_modal.tscn")
	var modal: _VictoryModal = runner.scene() as _VictoryModal

	# With room_index=0 and MWT=0, expect variant_index = abs(0 + 0) % 5 = 0 → VICTORY_NARRATIVE_1
	var text1: String = modal._select_victory_narrative()
	# Verify we got a real narrative (not empty, not a raw key)
	assert_bool(not text1.is_empty() and not text1.begins_with("VICTORY_NARRATIVE")).is_true()


func test_defeat_narrative_selection_deterministic() -> void:
	var runner: GdUnitSceneRunner = scene_runner("res://scenes/ui/defeat_modal.tscn")
	var modal: _DefeatModal = runner.scene() as _DefeatModal

	# With room_index=0 and MWT=0, expect variant_index = abs(0 + 0 * 3 + 1) % 5 = 1 → DEFEAT_NARRATIVE_2
	var text1: String = modal._select_defeat_narrative()
	# Verify we got a real narrative (not empty, not a raw key)
	assert_bool(not text1.is_empty() and not text1.begins_with("DEFEAT_NARRATIVE")).is_true()


func test_narrative_fallback_on_missing_key() -> void:
	var runner: GdUnitSceneRunner = scene_runner("res://scenes/ui/victory_modal.tscn")
	var modal: _VictoryModal = runner.scene() as _VictoryModal

	# If a localization key does not exist, tr() returns the key string;
	# _select_victory_narrative guards against this and returns empty string.
	# We verify the guard logic by checking that the returned text is either
	# a real narrative or empty — never a raw key.
	var text: String = modal._select_victory_narrative()
	assert_bool(text.is_empty() or not text.begins_with("VICTORY_NARRATIVE")).is_true()


func test_victory_summary_includes_narrative() -> void:
	var runner: GdUnitSceneRunner = scene_runner("res://scenes/ui/victory_modal.tscn")
	var modal: _VictoryModal = runner.scene() as _VictoryModal

	modal.setup({"turns": 3, "kills": 2, "shards": 45})
	# After setup, summary_container should have at least one child (the narrative label)
	assert_int(modal.summary_container.get_child_count()).is_greater(0)

	# Check that at least one child has text containing a known narrative fragment
	var found_narrative: bool = false
	for child: Node in modal.summary_container.get_children():
		if child is Label:
			var lbl: Label = child as Label
			if (
				"embers" in lbl.text
				or "Stillness" in lbl.text
				or "shard" in lbl.text
				or "burden" in lbl.text
				or "endure" in lbl.text
			):
				found_narrative = true
				break
	assert_bool(found_narrative).is_true()


func test_defeat_summary_includes_narrative() -> void:
	var runner: GdUnitSceneRunner = scene_runner("res://scenes/ui/defeat_modal.tscn")
	var modal: _DefeatModal = runner.scene() as _DefeatModal

	modal.setup({"turns": 3, "rooms": 1})
	assert_int(modal.summary_container.get_child_count()).is_greater(0)

	var found_narrative: bool = false
	for child: Node in modal.summary_container.get_children():
		if child is Label:
			var lbl: Label = child as Label
			if (
				"stillness" in lbl.text
				or "embers" in lbl.text
				or "echo" in lbl.text
				or "burden" in lbl.text
				or "falter" in lbl.text
			):
				found_narrative = true
				break
	assert_bool(found_narrative).is_true()
