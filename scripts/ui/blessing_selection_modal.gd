class_name BlessingSelectionModal
extends Control
## BlessingSelectionModal (FIX #599)
## Displays 3 run Blessings at the start of a run for player selection.

signal blessing_chosen(index: int)

var _blessing_data: Array[Dictionary] = []

@onready var _cards_container: HBoxContainer = HBoxContainer.new()


func _ready() -> void:
	anchors_preset = Control.PRESET_CENTER
	custom_minimum_size = Vector2(800, 400)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.07, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title: Label = Label.new()
	title.text = tr("BLESSING_SELECT_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.position = Vector2(0, 20)
	title.size = Vector2(get_viewport_rect().size.x, 40)
	add_child(title)

	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 24)
	_cards_container.position = Vector2(0, 80)
	add_child(_cards_container)

	var instruction: Label = Label.new()
	instruction.text = tr("BLESSING_SELECT_INSTRUCTION")
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 14)
	instruction.position = Vector2(0, 340)
	instruction.size = Vector2(get_viewport_rect().size.x, 30)
	add_child(instruction)

	process_mode = Node.PROCESS_MODE_ALWAYS


## Set the 3 blessings to display.
func set_blessings(blessings: Array[Dictionary]) -> void:
	_blessing_data = blessings
	_clear_cards()
	for i: int in range(blessings.size()):
		var card: PanelContainer = _build_card(blessings[i], i)
		_cards_container.add_child(card)


func _clear_cards() -> void:
	for child: Node in _cards_container.get_children():
		_cards_container.remove_child(child)
		child.queue_free()


func _build_card(data: Dictionary, index: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 240)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_color = Color(0.4, 0.35, 0.25, 1.0)  # Ember gold border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)

	var name_label: Label = Label.new()
	name_label.text = tr(data.get("name_key", "Unknown"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))
	vbox.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = tr(data.get("description_key", ""))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)

	var tags: Array = data.get("tags", []) as Array
	var tags_str: String = ", ".join(tags)
	var tags_label: Label = Label.new()
	tags_label.text = "[%s]" % tags_str
	tags_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tags_label.add_theme_font_size_override("font_size", 11)
	tags_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(tags_label)

	var select_btn: Button = Button.new()
	select_btn.text = tr("BLESSING_SELECT_BUTTON")
	select_btn.custom_minimum_size = Vector2(120, 36)
	select_btn.pressed.connect(_on_select.bind(index))
	vbox.add_child(select_btn)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_child(vbox)
	card.add_child(margin)

	return card


func _on_select(index: int) -> void:
	blessing_chosen.emit(index)
	queue_free()
