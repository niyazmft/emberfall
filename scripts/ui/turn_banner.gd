extends Control
## TurnBanner (DON-192)
## Displays animated combat phase transitions.

var _fade_duration: float = 0.3
var _slide_duration: float = 0.5
var _display_duration: float = 1.2

@onready var banner_background: ColorRect = $Background
@onready var turn_label: Label = $Label


func _ready() -> void:
	modulate.a = 0.0
	visible = false

	# Load config
	var config: Node = AutoloadHelper.config_loader()
	if config:
		_fade_duration = config.getValue("turn_banner", "fade_duration", 0.3)
		_slide_duration = config.getValue("turn_banner", "slide_duration", 0.5)
		_display_duration = config.getValue("turn_banner", "display_duration", 1.2)

	# Connect to EventBus
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.connect(_on_combat_started)
		eb.turn_started.connect(_on_turn_started)


func display_message(text: String, color: Color = Color.WHITE) -> void:
	turn_label.text = text
	turn_label.modulate = color

	visible = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, _fade_duration)

	# Slide in from left
	position.x = -size.x
	(
		tween
		. tween_property(self, "position:x", 0.0, _slide_duration)
		. set_trans(Tween.TRANS_QUINT)
		. set_ease(Tween.EASE_OUT)
	)

	await tween.finished
	await get_tree().create_timer(_display_duration).timeout

	var fade_out := create_tween().set_parallel(true)
	fade_out.tween_property(self, "modulate:a", 0.0, _fade_duration)
	(
		fade_out
		. tween_property(self, "position:x", size.x, _slide_duration)
		. set_trans(Tween.TRANS_QUINT)
		. set_ease(Tween.EASE_IN)
	)

	await fade_out.finished
	visible = false


func _on_combat_started(_room_index: int, _room_data: Dictionary) -> void:
	display_message(
		(
			tr("HUD_COMBAT_START")
			if TranslationServer.has_message("HUD_COMBAT_START")
			else "COMBAT START"
		),
		Color.ORANGE
	)


func _on_turn_started(entity: Entity, is_player: bool) -> void:
	if is_player:
		display_message(
			(
				tr("HUD_PLAYER_TURN_BANNER")
				if TranslationServer.has_message("HUD_PLAYER_TURN_BANNER")
				else "PLAYER TURN"
			),
			Color.GREEN
		)
	else:
		var enemy_name: String = entity.entity_name if entity else "ENEMY"
		var msg: String = (
			tr("HUD_ENEMY_TURN_BANNER") % enemy_name
			if TranslationServer.has_message("HUD_ENEMY_TURN_BANNER")
			else enemy_name + " TURN"
		)
		display_message(msg, Color.RED)
