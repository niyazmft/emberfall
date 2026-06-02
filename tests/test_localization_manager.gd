extends SceneTree

## Test: LocalizationManager
## Verifies that translations are loaded and correctly applied.


func _initialize() -> void:
	# LocalizationManager is an autoload, but since we are running this script
	# via 'godot -s', the SceneTree doesn't automatically load autoloads
	# from project.godot for THIS script's tree. We need to manually add it
	# to match the runtime environment as closely as possible.
	var lm_script := load("res://scripts/autoload/localization_manager.gd") as GDScript
	var lm: Node = lm_script.new()
	lm.name = "LocalizationManager"
	root.add_child(lm)

	# Give it a frame to initialize
	await process_frame

	var success: bool = true
	success = success and await test_translations_loaded()
	success = success and await test_set_locale()

	if success:
		print("PASSED: test_localization_manager.gd")
		quit(0)
	else:
		print("FAILED: test_localization_manager.gd")
		quit(1)


func test_translations_loaded() -> bool:
	print("  - Verifying translations are loaded...")

	# Default locale should be "en"
	TranslationServer.set_locale("en")

	var keys_to_test: Dictionary = {
		"MENU_TITLE": "Emberfall",
		"BE_MWT_0": "[A low rumble spreads beneath you]",
		"menu.title.continue": "Continue"
	}

	for key: String in keys_to_test:
		var expected: String = keys_to_test[key]
		var actual: String = tr(key)
		if actual != expected:
			push_error("Expected tr('%s') to be '%s', but got '%s'" % [key, expected, actual])
			return false

	print("    [OK] English translations verified.")
	return true


func test_set_locale() -> bool:
	print("  - Verifying locale switching...")

	var lm: Node = root.get_node("LocalizationManager")

	# Test German
	lm.set_locale("de")
	var key_de: String = "menu.title.continue"
	var expected_de: String = "Fortsetzen"
	var actual_de: String = tr(key_de)

	if actual_de != expected_de:
		push_error(
			"Expected tr('%s') to be '%s' (DE), but got '%s'" % [key_de, expected_de, actual_de]
		)
		return false

	# Test French
	lm.set_locale("fr")
	var key_fr: String = "menu.title.quit"
	var expected_fr: String = "Quitter"
	var actual_fr: String = tr(key_fr)

	if actual_fr != expected_fr:
		push_error(
			"Expected tr('%s') to be '%s' (FR), but got '%s'" % [key_fr, expected_fr, actual_fr]
		)
		return false

	# Reset to English
	lm.set_locale("en")

	print("    [OK] Locale switching verified.")
	return true
