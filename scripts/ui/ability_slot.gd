extends Button
## AbilitySlot (DON-196)
## Individual slot for the hotbar, managing icon, cooldown, and selection state.

@onready var icon_rect: TextureRect = $Icon
@onready var cooldown_overlay: TextureProgressBar = $CooldownOverlay
@onready var keybind_label: Label = $KeybindLabel
@onready var selected_border: Panel = $SelectedBorder

var ability_id: String = ""


func _ready() -> void:
	# Default states
	selected_border.hide()
	cooldown_overlay.value = 0
	_update_visuals()


## Populates the slot with ability data.
func set_ability_data(data: Dictionary) -> void:
	ability_id = str(data.get("id", ""))
	var abilityName: String = str(data.get("name", ""))
	if ability_id != "" and abilityName == "":
		abilityName = "Unknown"

	var iconPath: String = str(data.get("icon", ""))
	var keybind: String = str(data.get("keybind", ""))
	var cooldownMax: float = float(data.get("cooldown_max", 0))
	var cooldownCurrent: float = float(data.get("cooldown_current", 0))

	tooltip_text = abilityName
	keybind_label.text = keybind

	if not iconPath.is_empty() and ResourceLoader.exists(iconPath):
		icon_rect.texture = load(iconPath) as Texture2D
	else:
		icon_rect.texture = null

	update_cooldown(cooldownCurrent, cooldownMax)
	_update_visuals()


## Updates the cooldown progress bar.
func update_cooldown(current: float, maxVal: float) -> void:
	if maxVal > 0:
		cooldown_overlay.max_value = maxVal
		cooldown_overlay.value = current
		cooldown_overlay.show()

		# If on cooldown, we might want to grey out the icon
		if current > 0:
			icon_rect.modulate = Color(0.3, 0.3, 0.3)
			disabled = true
		else:
			icon_rect.modulate = Color.WHITE
			disabled = false
	else:
		cooldown_overlay.value = 0
		cooldown_overlay.hide()
		icon_rect.modulate = Color.WHITE
		disabled = false


## Toggles the selection highlight.
func set_selected(isSelected: bool) -> void:
	if isSelected:
		selected_border.show()
	else:
		selected_border.hide()


func _update_visuals() -> void:
	if ability_id.is_empty():
		modulate.a = 0.5  # Empty state
		keybind_label.hide()
	else:
		modulate.a = 1.0
		keybind_label.show()
