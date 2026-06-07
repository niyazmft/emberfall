extends Control

## SettingsPanel
## Manages UI for game settings.

signal back_pressed

@onready var _margin_container: MarginContainer = $MarginContainer

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _mute_check: CheckBox = %MuteCheck

@onready var _resolution_option: OptionButton = %ResolutionOption
@onready var _fullscreen_check: CheckBox = %FullscreenCheck
@onready var _vsync_check: CheckBox = %VSyncCheck
@onready var _apply_button: Button = %ApplyButton

@onready var _shake_slider: HSlider = %ShakeSlider
@onready var _cvd_option: OptionButton = %CVDOption

@onready var _input_hints_option: OptionButton = %InputHintsOption
@onready var _remap_panel: Control = %RemapPanel
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton
@onready var _help_label: Label = %HelpLabel

var _settings_help: Dictionary = {}
var _resolutions: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1024, 576),
]


func _ready() -> void:
	SafeZoneManager.safe_area_changed.connect(_on_safe_area_changed)
	_apply_safe_area()

	_load_help_data()
	_setup_options()
	_load_ui_from_settings()
	_connect_signals()
	_setup_help_listeners()


func _load_help_data() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl:
		if not cl.isLoaded():
			await cl.ready

		# We know the keys in settings_help.json from our step 2
		var help_keys: Array[String] = [
			"MasterSlider",
			"MusicSlider",
			"SFXSlider",
			"MuteCheck",
			"ResolutionOption",
			"FullscreenCheck",
			"VSyncCheck",
			"ApplyButton",
			"ShakeSlider",
			"CVDOption",
			"InputHintsOption",
			"ResetButton",
			"BackButton"
		]
		for key in help_keys:
			var val: Variant = cl.getValue(key)
			if val is String:
				_settings_help[key] = val


func _setup_options() -> void:
	_resolution_option.clear()
	for res: Vector2i in _resolutions:
		_resolution_option.add_item("%dx%d" % [res.x, res.y])

	_input_hints_option.clear()
	_input_hints_option.add_item(tr("OPTION_AUTO"), 0)
	_input_hints_option.add_item(tr("OPTION_KBM"), 1)
	_input_hints_option.add_item(tr("OPTION_GP"), 2)

	_cvd_option.clear()
	_cvd_option.add_item(tr("CVD_NONE"), 0)
	_cvd_option.add_item(tr("CVD_PROTANOPIA"), 1)
	_cvd_option.add_item(tr("CVD_DEUTERANOPIA"), 2)
	_cvd_option.add_item(tr("CVD_TRITANOPIA"), 3)


func _load_ui_from_settings() -> void:
	var sm: Node = AutoloadHelper.settings_manager()
	if sm == null:
		return
	var s: Dictionary = sm.get("settings")

	# Audio
	var audio_cfg: Dictionary = s.get("audio", {}) as Dictionary
	_master_slider.value = audio_cfg.get("master_volume", 1.0)
	_music_slider.value = audio_cfg.get("music_volume", 0.8)
	_sfx_slider.value = audio_cfg.get("sfx_volume", 0.8)
	_mute_check.button_pressed = audio_cfg.get("mute", false)

	# Video
	var video_cfg: Dictionary = s.get("video", {}) as Dictionary
	var current_res := Vector2i(
		video_cfg.get("resolution_width", 1920), video_cfg.get("resolution_height", 1080)
	)
	var res_index := _resolutions.find(current_res)
	if res_index != -1:
		_resolution_option.selected = res_index

	_fullscreen_check.button_pressed = video_cfg.get("fullscreen", true)
	_vsync_check.button_pressed = video_cfg.get("vsync", true)

	# Accessibility
	var access_cfg: Dictionary = s.get("accessibility", {}) as Dictionary
	_shake_slider.value = access_cfg.get("screen_shake", 1.0)
	_cvd_option.selected = access_cfg.get("cvd_sim", 0)

	# Controls
	var controls_cfg: Dictionary = s.get("controls", {}) as Dictionary
	_input_hints_option.selected = controls_cfg.get("input_hints", 0)
	if _remap_panel.has_method("refresh"):
		_remap_panel.call("refresh")


func _connect_signals() -> void:
	_master_slider.value_changed.connect(_on_audio_changed.bind("master_volume"))
	_music_slider.value_changed.connect(_on_audio_changed.bind("music_volume"))
	_sfx_slider.value_changed.connect(_on_audio_changed.bind("sfx_volume"))
	_mute_check.toggled.connect(_on_audio_changed.bind("mute"))

	_apply_button.pressed.connect(_on_apply_video_settings)

	_shake_slider.value_changed.connect(_on_accessibility_changed.bind("screen_shake"))
	_cvd_option.item_selected.connect(_on_accessibility_changed.bind("cvd_sim"))

	_input_hints_option.item_selected.connect(_on_controls_changed.bind("input_hints"))

	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func _on_audio_changed(value: Variant, key: String) -> void:
	var sm: Node = AutoloadHelper.settings_manager()
	if sm != null:
		var settings: Dictionary = sm.get("settings")
		if settings.has("audio"):
			settings["audio"][key] = value
			sm.call("apply_audio_settings")


func _on_apply_video_settings() -> void:
	var am: _UIAudioManager = AutoloadHelper.get_autoload("UIAudioManager")
	if am:
		am.play_ui_sound("apply")
	var hm: _HapticsManager = AutoloadHelper.get_autoload("HapticsManager")
	if hm:
		hm.trigger_haptic("apply")

	var sm: Node = AutoloadHelper.settings_manager()
	if sm == null:
		return
	var idx: int = _resolution_option.selected
	var settings: Dictionary = sm.get("settings")
	if not settings.has("video"):
		return

	if idx >= 0 and idx < _resolutions.size():
		var res: Vector2i = _resolutions[idx]
		settings["video"]["resolution_width"] = res.x
		settings["video"]["resolution_height"] = res.y
	settings["video"]["fullscreen"] = _fullscreen_check.button_pressed
	settings["video"]["vsync"] = _vsync_check.button_pressed
	sm.call("apply_video_settings")
	sm.call("save_settings")


func _on_accessibility_changed(value: Variant, key: String) -> void:
	var sm: Node = AutoloadHelper.settings_manager()
	if sm != null:
		var settings: Dictionary = sm.get("settings")
		if settings.has("accessibility"):
			settings["accessibility"][key] = value
			sm.call("apply_accessibility_settings")


func _on_controls_changed(index: int, key: String) -> void:
	var sm: Node = AutoloadHelper.settings_manager()
	if sm != null:
		var settings: Dictionary = sm.get("settings")
		if settings.has("controls"):
			settings["controls"][key] = index


func _on_reset_pressed() -> void:
	var scene: PackedScene = load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if scene:
		var modal: Node = scene.instantiate()
		modal.call("setup", "CONFIRM_RESET_SETTINGS_TITLE", "CONFIRM_RESET_SETTINGS_BODY")
		modal.connect("confirmed", _on_reset_confirmed)
		LayerManager.add_modal(modal)


func _on_reset_confirmed() -> void:
	var sm: Node = AutoloadHelper.settings_manager()
	if sm != null:
		sm.call("reset_to_defaults")
		_load_ui_from_settings()


func _setup_help_listeners() -> void:
	var controls: Array[Control] = [
		_master_slider,
		_music_slider,
		_sfx_slider,
		_mute_check,
		_resolution_option,
		_fullscreen_check,
		_vsync_check,
		_apply_button,
		_shake_slider,
		_cvd_option,
		_input_hints_option,
		_reset_button,
		_back_button
	]

	for control in controls:
		control.mouse_entered.connect(_on_control_hovered.bind(control.name))
		control.focus_entered.connect(_on_control_hovered.bind(control.name))
		control.mouse_exited.connect(_clear_help_text)
		control.focus_exited.connect(_clear_help_text)

		if control is Button or control is CheckBox or control is OptionButton:
			if control.has_signal("pressed"):
				control.pressed.connect(_on_control_clicked)
			elif control.has_signal("item_selected"):
				control.item_selected.connect(func(_idx: int) -> void: _on_control_clicked())
		elif control is HSlider:
			control.drag_ended.connect(func(_changed: bool) -> void: _on_control_clicked())


func _on_control_hovered(control_name: String) -> void:
	_update_help_text(control_name)
	var am: _UIAudioManager = AutoloadHelper.get_autoload("UIAudioManager")
	if am:
		am.play_ui_sound("hover")
	var hm: _HapticsManager = AutoloadHelper.get_autoload("HapticsManager")
	if hm:
		hm.trigger_haptic("hover")


func _on_control_clicked() -> void:
	var am: _UIAudioManager = AutoloadHelper.get_autoload("UIAudioManager")
	if am:
		am.play_ui_sound("click")
	var hm: _HapticsManager = AutoloadHelper.get_autoload("HapticsManager")
	if hm:
		hm.trigger_haptic("click")


func _update_help_text(control_name: String) -> void:
	if _settings_help.has(control_name):
		_help_label.text = tr(_settings_help[control_name])


func _clear_help_text() -> void:
	_help_label.text = " "


func _on_back_pressed() -> void:
	var am: _UIAudioManager = AutoloadHelper.get_autoload("UIAudioManager")
	if am:
		am.play_ui_sound("cancel")
	var hm: _HapticsManager = AutoloadHelper.get_autoload("HapticsManager")
	if hm:
		hm.trigger_haptic("cancel")

	var sm: Node = AutoloadHelper.settings_manager()
	if sm != null:
		sm.call("sync_bindings_to_settings")
		sm.call("save_settings")
	back_pressed.emit()
	hide()


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	var margins: Dictionary = SafeZoneManager.get_safe_margins() as Dictionary
	_margin_container.add_theme_constant_override("margin_left", int(margins.get("left", 0)))
	_margin_container.add_theme_constant_override("margin_top", int(margins.get("top", 0)))
	_margin_container.add_theme_constant_override("margin_right", int(margins.get("right", 0)))
	_margin_container.add_theme_constant_override("margin_bottom", int(margins.get("bottom", 0)))
