extends Control
## Hotbar (DON-196)
## Manages action slots and responsive overflow.

@onready var slots_container: HBoxContainer = $HBoxContainer/ScrollContainer/HBoxContainer
@onready var left_arrow: Button = $HBoxContainer/LeftArrow
@onready var right_arrow: Button = $HBoxContainer/RightArrow
@onready var scroll_container: ScrollContainer = $HBoxContainer/ScrollContainer

const MAX_VISIBLE_SLOTS: int = 6
const SLOT_WIDTH: float = 48.0
const SPACING: float = 4.0

var _player_entity: Entity = null
var _slot_ability_ids: Array[String] = []
var _slot_callables: Array[Callable] = []


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.run_started.connect(_on_run_started)

	_setup_slot_buttons()
	_refresh_hotbar()


func _exit_tree() -> void:
	if get_tree() and get_tree().root:
		if get_tree().root.size_changed.is_connected(_on_viewport_resized):
			get_tree().root.size_changed.disconnect(_on_viewport_resized)

	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb and eb.run_started.is_connected(_on_run_started):
		eb.run_started.disconnect(_on_run_started)

	_disconnect_slot_buttons()

	if _player_entity and _player_entity.ap_changed.is_connected(_on_ap_changed):
		_player_entity.ap_changed.disconnect(_on_ap_changed)


func set_player_entity(entity: Entity) -> void:
	if _player_entity and _player_entity.ap_changed.is_connected(_on_ap_changed):
		_player_entity.ap_changed.disconnect(_on_ap_changed)
	_player_entity = entity
	if _player_entity:
		if not _player_entity.ap_changed.is_connected(_on_ap_changed):
			_player_entity.ap_changed.connect(_on_ap_changed)
	_update_slot_states()


func _setup_slot_buttons() -> void:
	var slots: Array[Node] = slots_container.get_children()
	_slot_ability_ids.resize(slots.size())
	_slot_callables.resize(slots.size())
	for i: int in range(slots.size()):
		var slot_btn: Button = slots[i] as Button
		if slot_btn:
			var callable: Callable = _on_slot_pressed.bind(i)
			_slot_callables[i] = callable
			slot_btn.pressed.connect(callable)


func _disconnect_slot_buttons() -> void:
	var slots: Array[Node] = slots_container.get_children()
	for i: int in range(slots.size()):
		var slot_btn: Button = slots[i] as Button
		if slot_btn and i < _slot_callables.size() and _slot_callables[i] != null:
			if slot_btn.pressed.is_connected(_slot_callables[i]):
				slot_btn.pressed.disconnect(_slot_callables[i])


func _on_run_started(_seed: int) -> void:
	_refresh_hotbar()


func _on_viewport_resized() -> void:
	var viewport_width := get_viewport().get_visible_rect().size.x
	# DESIGN_WIDTH is 320. 360 design px is 360/320 * DESIGN_WIDTH.
	# If viewport width is less than 360 relative to a 320 base.
	# Godot's stretch mode "canvas_items" means the viewport size we see is the design size if using scaling.
	# Acceptance criteria says "viewport width < 360 design px".

	if viewport_width < 360.0:
		left_arrow.show()
		right_arrow.show()
		# Enforce 6 visible slots max by limiting scroll container width
		scroll_container.custom_minimum_size.x = (SLOT_WIDTH + SPACING) * MAX_VISIBLE_SLOTS
	else:
		left_arrow.hide()
		right_arrow.hide()
		scroll_container.custom_minimum_size.x = 0  # Expand naturally


func _refresh_hotbar() -> void:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	var ability_mgr: _AbilityManager = AutoloadHelper.ability_manager()

	if not config or not ability_mgr:
		_clear_all_slots()
		_update_slot_states()
		return

	var bindings: Variant = config.getValue("hotbar_bindings", "default_layout")
	if not bindings is Array:
		push_warning("Hotbar: No default_layout found in hotbar_bindings.")
		_clear_all_slots()
		_update_slot_states()
		return

	var slots: Array[Node] = slots_container.get_children()
	for i: int in range(slots.size()):
		var slot_btn: Button = slots[i] as Button
		if not slot_btn:
			_slot_ability_ids[i] = ""
			continue

		if i < bindings.size() and bindings[i] != null:
			var ability_id: String = str(bindings[i])
			var ability: Ability = ability_mgr.getAbility(ability_id)
			if ability:
				slot_btn.text = tr(ability.nameKey)
				slot_btn.tooltip_text = tr(ability.descriptionKey)
				slot_btn.show()
				_slot_ability_ids[i] = ability_id
			else:
				slot_btn.text = ""
				slot_btn.tooltip_text = ""
				slot_btn.hide()
				_slot_ability_ids[i] = ""
		else:
			slot_btn.text = ""
			slot_btn.tooltip_text = ""
			slot_btn.hide()
			_slot_ability_ids[i] = ""

	_update_slot_states()


func _update_slot_states() -> void:
	var ability_mgr: _AbilityManager = AutoloadHelper.ability_manager()
	var slots: Array[Node] = slots_container.get_children()
	for i: int in range(slots.size()):
		var slot_btn: Button = slots[i] as Button
		if not slot_btn:
			continue
		if i < _slot_ability_ids.size() and not _slot_ability_ids[i].is_empty():
			var ability: Ability = (
				ability_mgr.getAbility(_slot_ability_ids[i]) if ability_mgr else null
			)
			if ability and _player_entity != null:
				slot_btn.disabled = _player_entity.ap < ability.apCost
			else:
				slot_btn.disabled = true
		else:
			slot_btn.disabled = true


func _on_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slot_ability_ids.size():
		return
	var ability_id: String = _slot_ability_ids[slot_index]
	if ability_id.is_empty():
		return
	var ability_mgr: _AbilityManager = AutoloadHelper.ability_manager()
	if ability_mgr and _player_entity:
		ability_mgr.use_ability(_player_entity, ability_id)


func _on_ap_changed(_new_ap: int, _old_ap: int) -> void:
	_update_slot_states()


func _clear_all_slots() -> void:
	var slots: Array[Node] = slots_container.get_children()
	for i: int in range(slots.size()):
		var slot: Node = slots[i]
		if slot is Button:
			var slot_btn: Button = slot as Button
			slot_btn.text = ""
			slot_btn.tooltip_text = ""
			slot_btn.hide()
			if i < _slot_ability_ids.size():
				_slot_ability_ids[i] = ""


func _clear_slot(slot_btn: Button) -> void:
	slot_btn.text = ""
	slot_btn.tooltip_text = ""
	slot_btn.hide()
