extends Control
## TurnBanner (DON-192)
## Displays animated combat phase transitions with visual fanfare.

var _fade_duration: float = 0.3
var _slide_duration: float = 0.5
var _display_duration: float = 1.5

const COLOR_GOLD: Color = Color(1.0, 0.84, 0.0)
const COLOR_RED: Color = Color(0.9, 0.2, 0.2)

@onready var banner_background: ColorRect = $Background
@onready var banner_panel: Panel = $Background/Panel
@onready var turn_label: Label = $Label
@onready var particles: CPUParticles2D = $Particles

var _is_player_turn: bool = true


func _ready() -> void:
	modulate.a = 0.0
	visible = false
	scale = Vector2.ZERO

	# Configure panel StyleBoxFlat for rounded decorative backing
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.92)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_GOLD
	banner_panel.add_theme_stylebox_override("panel", style)

	# Configure particles for burst effect
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 24
	particles.lifetime = 0.5
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = COLOR_GOLD

	# Load config
	var config: Node = AutoloadHelper.config_loader()
	if config:
		_fade_duration = config.getValue("turn_banner", "fade_duration", 0.3)
		_slide_duration = config.getValue("turn_banner", "slide_duration", 0.5)
		_display_duration = config.getValue("turn_banner", "display_duration", 1.5)

	# Connect to EventBus
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		eb.room_entered.connect(_on_combat_started)
		eb.turn_started.connect(_on_turn_started)


func _exit_tree() -> void:
	var eb: _EventBus = AutoloadHelper.event_bus()
	if eb:
		if eb.room_entered.is_connected(_on_combat_started):
			eb.room_entered.disconnect(_on_combat_started)
		if eb.turn_started.is_connected(_on_turn_started):
			eb.turn_started.disconnect(_on_turn_started)


func _show_banner(p_text: String, p_is_player: bool) -> void:
	_is_player_turn = p_is_player
	turn_label.text = p_text

	var accent_color: Color = COLOR_GOLD if p_is_player else COLOR_RED
	turn_label.modulate = accent_color
	particles.color = accent_color

	# Update panel border color
	var style: StyleBoxFlat = banner_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.border_color = accent_color
		banner_panel.add_theme_stylebox_override("panel", style)

	visible = true
	modulate.a = 1.0

	# Scale in from zero with TRANS_BACK easing
	scale = Vector2.ZERO
	var scale_tween := create_tween()
	(
		scale_tween
		. tween_property(self, "scale", Vector2.ONE, 0.3)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)

	# Brief gold/red glow flash on label
	var glow_tween := create_tween()
	glow_tween.tween_property(turn_label, "modulate", Color.WHITE, 0.15)
	glow_tween.tween_interval(0.1)
	glow_tween.tween_property(turn_label, "modulate", accent_color, 0.15)

	# Particle burst
	particles.emitting = true

	await scale_tween.finished
	await get_tree().create_timer(_display_duration).timeout

	# Fade out
	var fade_out := create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, _fade_duration)
	await fade_out.finished
	visible = false


func display_message(p_text: String, p_color: Color = Color.WHITE) -> void:
	## Legacy API: delegates to _show_banner with player-turn treatment.
	_show_banner(p_text, p_color == Color.GREEN or p_color == COLOR_GOLD)


func _on_combat_started(_room_index: int, _room_data: Dictionary) -> void:
	_show_banner(tr("HUD_COMBAT_START"), true)


func _on_turn_started(p_entity: Entity, p_is_player: bool) -> void:
	if p_is_player:
		_show_banner(tr("HUD_PLAYER_TURN_BANNER"), true)
	else:
		var enemy_name: String = p_entity.entity_name if p_entity else "ENEMY"
		var msg: String = tr("HUD_ENEMY_TURN_BANNER") % enemy_name
		_show_banner(msg, false)
