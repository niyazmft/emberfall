class_name _BurdenNarrativeModal
extends Control
## BurdenNarrativeModal
## Displays the Burden Event narrative to the player after moral weight threshold
## is crossed. A simple acknowledge-and-continue modal for the vertical slice.
##
## Emits `continued` when the player presses the Continue button.

signal continued

var _result: BurdenEventResult = null


func setup(result: BurdenEventResult) -> void:
	_result = result
	_build_ui()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _build_ui() -> void:
	# Background dim
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85)
	add_child(bg)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Panel using project theme
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	# Margin padding
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	# Vertical layout
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	if _result.numbness_cap_reached:
		title.text = tr("BE_NUMBNESS_TITLE")
	elif _result.is_first:
		title.text = tr("BE_PHASE_B_TITLE_FIRST")
	else:
		title.text = tr("BE_PHASE_B_TITLE_REPEAT")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	# Phase B narrative
	var narrative := Label.new()
	var narrative_text: String = _result.phase_b_text
	if narrative_text.is_empty() and _result.numbness_cap_reached:
		narrative_text = tr(_result.phase_b_localization_key)
		narrative.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	narrative.text = narrative_text
	narrative.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narrative.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narrative.add_theme_font_size_override("font_size", 18)
	vbox.add_child(narrative)

	# Phase C consequence
	if not _result.phase_c_text.is_empty():
		var phase_c := Label.new()
		phase_c.text = _result.phase_c_text
		phase_c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		phase_c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		phase_c.add_theme_font_size_override("font_size", 14)
		phase_c.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(phase_c)

	# Phase D return
	if not _result.phase_d_text.is_empty():
		var phase_d := Label.new()
		phase_d.text = _result.phase_d_text
		phase_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		phase_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		phase_d.add_theme_font_size_override("font_size", 14)
		phase_d.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
		vbox.add_child(phase_d)

	# Continue button
	var btn := Button.new()
	btn.text = tr("menu.title.continue")
	btn.custom_minimum_size = Vector2(200, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn)

	btn.grab_focus.call_deferred()


func _on_continue_pressed() -> void:
	continued.emit()
	queue_free()
