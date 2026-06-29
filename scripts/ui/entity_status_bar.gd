class_name EntityStatusBar
extends Control

## EntityStatusBar
## Displays HP via a styled ProgressBar with color-coded fill and numeric label,
## and AP via dynamic TextureRect pips (diamond shapes).

const _AP_FULL: Texture2D = preload("res://assets/sprites/ap_gem.png")
const _AP_EMPTY: Texture2D = preload("res://assets/sprites/ap_gem_empty.png")

var _lerp_speed: float = 10.0
var _target_hp: float = 0.0
var _max_hp: int = 1
var target_entity_node: Node2D = null

@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var ap_container: HBoxContainer = %APContainer


func _ready() -> void:
	process_priority = 100
	_load_config()
	_style_hp_bar()


func set_occluded(is_occluded: bool) -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_alpha: float = 0.15 if is_occluded else 1.0
	tween.tween_property(self, "modulate:a", target_alpha, 0.25)


func _load_config() -> void:
	var loader: _ConfigLoader = AutoloadHelper.config_loader()
	if loader:
		var feedback: Dictionary = loader.getValue("health_bar", "", {})
		if feedback:
			_lerp_speed = feedback.get("lerp_speed", 10.0)


func _style_hp_bar() -> void:
	"""Apply StyleBoxFlat with rounded corners, border, and background to the HP bar."""
	if hp_bar == null:
		return

	# Background style (empty portion of the bar)
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	bg_style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	hp_bar.add_theme_stylebox_override("background", bg_style)

	# Fill style will be set dynamically in _process based on HP percentage
	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	hp_bar.add_theme_stylebox_override("fill", fill_style)


func _process(delta: float) -> void:
	if hp_bar == null:
		return
	if is_instance_valid(target_entity_node):
		var viewport: Viewport = get_viewport()
		var camera: Camera2D = viewport.get_camera_2d() if viewport else null
		if camera != null and get_parent() is CanvasLayer:
			position = camera.unproject_position(
				target_entity_node.global_position + Vector2(-32, -60)
			)

	if DeterministicMath.absf(hp_bar.value - _target_hp) > 0.1:
		hp_bar.value = lerpf(hp_bar.value, _target_hp, _lerp_speed * delta)
	else:
		hp_bar.value = _target_hp

	_update_hp_color()


func _update_hp_color() -> void:
	"""Set HP bar fill color based on percentage: red → yellow → green."""
	if hp_bar == null or _max_hp <= 0:
		return

	var pct: float = hp_bar.value / float(_max_hp)
	var fill_color: Color

	if pct <= 0.33:
		# Low HP: red
		fill_color = Color(0.9, 0.15, 0.15)
	elif pct <= 0.66:
		# Medium HP: yellow/orange
		fill_color = Color(0.95, 0.75, 0.1)
	else:
		# High HP: green
		fill_color = Color(0.2, 0.85, 0.25)

	var fg_style: StyleBoxFlat = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fg_style != null and fg_style.bg_color != fill_color:
		fg_style.bg_color = fill_color


## Update HP bar and numeric label
func update_hp(p_current: int, p_max_hp: int) -> void:
	hp_bar.max_value = p_max_hp
	_max_hp = p_max_hp
	_target_hp = float(p_current)
	if hp_label != null:
		hp_label.text = "HP: %d/%d" % [p_current, p_max_hp]


## Deprecated: Use update_hp
func updateHp(p_current: int, p_max_hp: int) -> void:
	update_hp(p_current, p_max_hp)


## Update AP pips to show current AP out of max (yellow/gold diamond shapes)
func update_ap(p_current: int, p_max_ap: int = -1) -> void:
	var actual_max_ap: int = p_max_ap
	if actual_max_ap < 0:
		actual_max_ap = _get_ap_max()

	var current_child_count: int = ap_container.get_child_count()

	if actual_max_ap > current_child_count:
		for i: int in range(actual_max_ap - current_child_count):
			var pip: TextureRect = TextureRect.new()
			pip.custom_minimum_size = Vector2(12, 12)
			pip.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			ap_container.add_child(pip)
	elif actual_max_ap < current_child_count:
		for i: int in range(current_child_count - 1, actual_max_ap - 1, -1):
			var child: Node = ap_container.get_child(i)
			ap_container.remove_child(child)
			child.queue_free()

	for i: int in range(actual_max_ap):
		var pip: TextureRect = ap_container.get_child(i) as TextureRect
		if pip:
			pip.texture = _AP_FULL if i < p_current else _AP_EMPTY


## Deprecated: Use update_ap
func updateAp(p_current: int, p_max_ap: int) -> void:
	update_ap(p_current, p_max_ap)


func _get_ap_max() -> int:
	var config: _ConfigLoader = AutoloadHelper.config_loader()
	return (
		config.getValue("ap_bar", "segment_count", GameConstants.AP_MAX)
		if config
		else GameConstants.AP_MAX
	)
