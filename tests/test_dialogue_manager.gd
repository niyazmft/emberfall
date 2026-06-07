# GdUnitGeneratedTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")
# Test suite for DialogueManager
# Verification of loading, parsing, and data retrieval.
func test_dialogue_loading() -> void:
	var dm: _DialogueManager = DialogueManager as _DialogueManager

	# Test loading
	assert_bool(dm.hasDialogue("BE_B_FIRST_A")).is_true()
	var d: Dictionary = dm.getDialogue("BE_B_FIRST_A")
	assert_str(d.get("text") as String).starts_with("Three keepers")

	assert_bool(dm.hasDialogue("BE_PHASE_C")).is_true()


func test_non_existent_dialogue() -> void:
	var dm: _DialogueManager = DialogueManager as _DialogueManager
	assert_bool(dm.hasDialogue("NON_EXISTENT")).is_false()
	assert_dict(dm.getDialogue("NON_EXISTENT")).is_empty()


func test_dialogue_deep_copy() -> void:
	var dm: _DialogueManager = DialogueManager as _DialogueManager

	# Test deep copy (should be separate dict)
	var d1: Dictionary = dm.getDialogue("BE_PHASE_D")
	d1["text"] = "MODIFIED"

	var d2: Dictionary = dm.getDialogue("BE_PHASE_D")
	assert_str(d2.get("text") as String).is_not_equal("MODIFIED")
	assert_str(d2.get("text") as String).is_equal("You exhale. The embers cool.")


func test_nested_metadata_deep_copy() -> void:
	var dm: _DialogueManager = DialogueManager as _DialogueManager

	if dm.hasDialogue("BE_B_FIRST_A"):
		var d1: Dictionary = dm.getDialogue("BE_B_FIRST_A")
		var metadata: Dictionary = d1.get("metadata") as Dictionary
		metadata["title"] = "CORRUPTED"

		var d2: Dictionary = dm.getDialogue("BE_B_FIRST_A")
		var metadata2: Dictionary = d2.get("metadata") as Dictionary
		assert_str(metadata2.get("title") as String).is_equal("The Holding")
