extends Control
## TurnBanner (DON-192)
## Displays combat phase transitions (Turn Started, Combat Started, Victory/Defeat).

@onready var banner_panel: PanelContainer = %BannerPanel
@onready var banner_label: Label = %BannerLabel

var _current_tween: Tween


func _ready() -> void:
	# Hide initially
	modulate.a = 0.0
	banner_panel.position.x = -get_viewport_rect().size.x

	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.combat_started.connect(_on_combat_started)
		eb.turn_started.connect(_on_turn_started)
		eb.combat_ended.connect(_on_combat_ended)

	var szm: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if szm:
		szm.safe_area_changed.connect(_on_safe_area_changed)


func _on_combat_started() -> void:
	display_banner("PHASE_COMBAT_STARTED", Color.GRAY)


func _on_turn_started(_entity: Entity, is_player: bool) -> void:
	if is_player:
		display_banner("PHASE_PLAYER_TURN", Color.DARK_GREEN)
	else:
		display_banner("PHASE_ENEMY_TURN", Color.DARK_RED)


func _on_combat_ended(victory: bool) -> void:
	if victory:
		display_banner("PHASE_VICTORY", Color.GOLD)
	else:
		display_banner("PHASE_DEFEAT", Color.DARK_SLATE_BLUE)


func display_banner(text_key: String, color: Color) -> void:
	banner_label.text = tr(text_key)
	banner_panel.self_modulate = color

	if _current_tween:
		_current_tween.kill()

	_current_tween = create_tween().set_parallel(true)

	# Initial state for animation
	modulate.a = 0.0
	var screen_width: float = get_viewport_rect().size.x
	banner_panel.position.x = -screen_width

	# Slide and Fade In
	(
		_current_tween
		. tween_property(self, "modulate:a", 1.0, 0.4)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
	)
	(
		_current_tween
		. tween_property(banner_panel, "position:x", 0.0, 0.5)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)

	# Wait and Fade Out
	_current_tween.chain().tween_interval(1.5)
	_current_tween.chain().set_parallel(true)
	(
		_current_tween
		. tween_property(self, "modulate:a", 0.0, 0.4)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_IN)
	)
	(
		_current_tween
		. tween_property(banner_panel, "position:x", screen_width, 0.5)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_IN)
	)


func _on_safe_area_changed(_rect: Rect2) -> void:
	# Banners are typically centered and full width, so safe area might
	# mostly affect padding if we had any. For now, it ensures label is centered.
	pass
