class_name TurnBanner
extends Control

## TurnBanner
## Displays animated combat phase transitions.

@onready var label: Label = %BannerLabel
@onready var background: ColorRect = %Background

var _fade_duration: float = 0.5

func _ready() -> void:
	_load_config()
	modulate.a = 0.0

	EventBus.entity_state_changed.connect(_on_entity_state_changed)
	# Connect to other turn-related signals if available

func _load_config() -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()
	if loader:
		var feedback: Dictionary = loader.getValue("transitions", "", {})
		if feedback:
			_fade_duration = feedback.get("fade_duration", 0.5)

func show_banner(text: String, color: Color = Color.WHITE) -> void:
	label.text = text
	background.color = color
	background.color.a = 0.5

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, _fade_duration)
	tween.tween_interval(1.5)
	tween.tween_property(self, "modulate:a", 0.0, _fade_duration)

func _on_entity_state_changed(_entity: Entity, _old_state: Entity.State, new_state: Entity.State) -> void:
	# Example integration: show banner on certain state changes
	if new_state == Entity.State.DEAD:
		# show_banner("ENTITY DEFEATED", Color.RED)
		pass
