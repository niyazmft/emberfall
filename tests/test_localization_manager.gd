class_name TestLocalizationManager
extends GdUnitTestSuite


func test_translations_loaded() -> void:
	TranslationServer.set_locale("en")

	var keys_to_test: Dictionary = {
		"MENU_TITLE": "Emberfall",
		"BE_MWT_0": "[A low rumble spreads beneath you]",
		"menu.title.continue": "Continue"
	}

	for key: String in keys_to_test:
		var expected: String = keys_to_test[key]
		var actual: String = tr(key)
		assert_that(actual).is_equal(expected)


func test_set_locale() -> void:
	var lm_script := load("res://scripts/autoload/localization_manager.gd") as GDScript
	var lm: Node = auto_free(lm_script.new())
	add_child(lm)

	lm.set_locale("de")
	var key_de: String = "menu.title.continue"
	var expected_de: String = "Fortsetzen"
	var actual_de: String = tr(key_de)
	assert_that(actual_de).is_equal(expected_de)

	lm.set_locale("es")
	var key_es: String = "menu.title.continue"
	var expected_es: String = "Continuar"
	var actual_es: String = tr(key_es)
	assert_that(actual_es).is_equal(expected_es)

	lm.set_locale("fr")
	var key_fr: String = "menu.title.quit"
	var expected_fr: String = "Quitter"
	var actual_fr: String = tr(key_fr)
	assert_that(actual_fr).is_equal(expected_fr)

	lm.set_locale("en")
