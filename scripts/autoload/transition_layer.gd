class_name _TransitionLayer
extends CanvasLayer
## A global transition layer to handle screen fades.

signal fade_completed

@onready var color_rect: ColorRect = ColorRect.new()
var _loading_label: Label
var _transition_count: int = 0


func _ready() -> void:
	layer = 100  # Ensure it is on top of everything

	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

	_loading_label = Label.new()
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading_label.add_theme_font_size_override("font_size", 18)
	_loading_label.modulate.a = 0.0
	_loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loading_label)


func _show_loading_text() -> void:
	## Pick a random lore snippet using a deterministic seed.
	_transition_count += 1
	var seed_val: int = SeedGovernance.hash_int(_transition_count, "loading_lore")
	var idx: int = SeedGovernance.modulo_from_seed(seed_val, "lore_variant", 10)
	var key: String = "LOADING_LORE_%d" % (idx + 1)
	var text: String = tr(key)
	if text == key:
		# Fallback if translation key is missing
		var fallbacks: Array[String] = [
			"The Keepers were twelve. Now they are rumors.",
			"The embers remember what the world forgets.",
			"Every room is a question. Every fight is an answer.",
			"The burden is not carried. It is transferred.",
			"Echoes do not die. They wait.",
			"Stillness is not peace. It is preparation.",
			"The shards sing when no one listens.",
			"What falls may rise. What rises may fall.",
			"The Keepers fell so the world could stand.",
			"Silence is the loudest weight.",
		]
		text = fallbacks[idx]

	_loading_label.text = "[ %s ]" % text
	_loading_label.modulate.a = 1.0


func fade_out(duration: float = 0.5) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks during transition
	_show_loading_text()
	if OS.has_feature("headless"):
		color_rect.modulate.a = 1.0
		_loading_label.modulate.a = 0.0
		fade_completed.emit()
		return

	var tween: Tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished
	fade_completed.emit()


func fade_in(duration: float = 0.5) -> void:
	if OS.has_feature("headless"):
		color_rect.modulate.a = 0.0
		_loading_label.modulate.a = 0.0
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_completed.emit()
		return

	var tween: Tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished
	_loading_label.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_completed.emit()
