extends GdUnitTestSuite

const HOTBAR_SCENE: String = "res://scenes/ui/hotbar.tscn"


func test_hotbar_population() -> void:
	var hotbar: Control = load(HOTBAR_SCENE).instantiate() as Control
	add_child(hotbar)
	auto_free(hotbar)

	# Wait for _ready to finish (it calls _refresh_hotbar)
	await get_tree().process_frame

	var slots_container: HBoxContainer = hotbar.get_node(
		"HBoxContainer/ScrollContainer/HBoxContainer"
	)
	var slots: Array[Node] = slots_container.get_children()

	# Based on config/hotbar_bindings.json:
	# slot 0: strike_ember
	# slot 1: quick_dash
	# slot 2+: null (hidden)

	var slot0: Button = slots[0] as Button
	assert_bool(slot0.visible).is_true()
	assert_str(slot0.text).is_not_empty()
	# Check localization
	assert_str(slot0.text).is_equal(tr("SKILL_STRIKE_EMBER_NAME"))
	assert_str(slot0.tooltip_text).is_equal(tr("SKILL_STRIKE_EMBER_DESC"))

	var slot1: Button = slots[1] as Button
	assert_bool(slot1.visible).is_true()
	assert_str(slot1.text).is_equal(tr("SKILL_QUICK_DASH_NAME"))

	var slot2: Button = slots[2] as Button
	assert_bool(slot2.visible).is_false()
