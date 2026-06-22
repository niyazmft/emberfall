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
@onready var helpLabel: Label = %HelpLabel

@onready
var _tab_container: TabContainer = $MarginContainer/VBoxContainer/TabContainer as TabContainer

var settingsHelp: Dictionary = {}
var _bound_callables: Dictionary = {}
var _resolutions: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1024, 576),
]


func _ready() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz:
		sz.safe_area_changed.connect(_on_safe_area_changed)
	_apply_safe_area()

	_loadHelpData()
	_setup_options()
	_load_ui_from_settings()
	_connect_signals()
	_setupHelpListeners()
	_style_tab_container()


func _loadHelpData() -> void:
	var cl: _ConfigLoader = AutoloadHelper.config_loader()
	if cl:
		if not cl.isLoaded():
			await cl.ready

		var helpData: Variant = cl.getValue("settings_help")
		if helpData is Dictionary:
			for key: String in helpData:
				var val: Variant = helpData[key]
				if val is String:
					settingsHelp[key] = val


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
	var sm := AutoloadHelper.settings_manager()
	if sm == null:
		return
	var s: Dictionary = sm.settings

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
	var remap := _remap_panel as _RemapPanel
	if remap:
		remap.refresh()


func _exit_tree() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz and sz.safe_area_changed.is_connected(_on_safe_area_changed):
		sz.safe_area_changed.disconnect(_on_safe_area_changed)

	# Audio
	if (
		_bound_callables.has("master_volume")
		and _master_slider.value_changed.is_connected(_bound_callables["master_volume"])
	):
		_master_slider.value_changed.disconnect(_bound_callables["master_volume"])
	if (
		_bound_callables.has("music_volume")
		and _music_slider.value_changed.is_connected(_bound_callables["music_volume"])
	):
		_music_slider.value_changed.disconnect(_bound_callables["music_volume"])
	if (
		_bound_callables.has("sfx_volume")
		and _sfx_slider.value_changed.is_connected(_bound_callables["sfx_volume"])
	):
		_sfx_slider.value_changed.disconnect(_bound_callables["sfx_volume"])
	if _bound_callables.has("mute") and _mute_check.toggled.is_connected(_bound_callables["mute"]):
		_mute_check.toggled.disconnect(_bound_callables["mute"])

	# Video & Accessibility
	if _apply_button.pressed.is_connected(_on_apply_video_settings):
		_apply_button.pressed.disconnect(_on_apply_video_settings)
	if (
		_bound_callables.has("screen_shake")
		and _shake_slider.value_changed.is_connected(_bound_callables["screen_shake"])
	):
		_shake_slider.value_changed.disconnect(_bound_callables["screen_shake"])
	if (
		_bound_callables.has("cvd_sim")
		and _cvd_option.item_selected.is_connected(_bound_callables["cvd_sim"])
	):
		_cvd_option.item_selected.disconnect(_bound_callables["cvd_sim"])

	# Controls & Navigation
	if (
		_bound_callables.has("input_hints")
		and _input_hints_option.item_selected.is_connected(_bound_callables["input_hints"])
	):
		_input_hints_option.item_selected.disconnect(_bound_callables["input_hints"])
	if _reset_button.pressed.is_connected(_on_reset_pressed):
		_reset_button.pressed.disconnect(_on_reset_pressed)
	if _back_button.pressed.is_connected(_on_back_pressed):
		_back_button.pressed.disconnect(_on_back_pressed)

	# Help Listeners
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
	for control: Control in controls:
		var bound_hover: Callable = _bound_callables.get("hover_" + control.name, Callable())
		if bound_hover and control.mouse_entered.is_connected(bound_hover):
			control.mouse_entered.disconnect(bound_hover)
		if bound_hover and control.focus_entered.is_connected(bound_hover):
			control.focus_entered.disconnect(bound_hover)

		if control.mouse_exited.is_connected(_clearHelpText):
			control.mouse_exited.disconnect(_clearHelpText)
		if control.focus_exited.is_connected(_clearHelpText):
			control.focus_exited.disconnect(_clearHelpText)

		if control is Button or control is CheckBox or control is OptionButton:
			if control.has_signal("pressed") and control.pressed.is_connected(_onControlClicked):
				control.pressed.disconnect(_onControlClicked)
			elif (
				control.has_signal("item_selected")
				and control.item_selected.is_connected(_onControlClicked)
			):
				control.item_selected.disconnect(_onControlClicked)
		elif control is HSlider:
			if control.drag_ended.is_connected(_onControlClicked):
				control.drag_ended.disconnect(_onControlClicked)


func _connect_signals() -> void:
	_bound_callables["master_volume"] = _on_audio_changed.bind("master_volume")
	_master_slider.value_changed.connect(_bound_callables["master_volume"])
	_bound_callables["music_volume"] = _on_audio_changed.bind("music_volume")
	_music_slider.value_changed.connect(_bound_callables["music_volume"])
	_bound_callables["sfx_volume"] = _on_audio_changed.bind("sfx_volume")
	_sfx_slider.value_changed.connect(_bound_callables["sfx_volume"])
	_bound_callables["mute"] = _on_audio_changed.bind("mute")
	_mute_check.toggled.connect(_bound_callables["mute"])

	_apply_button.pressed.connect(_on_apply_video_settings)

	_bound_callables["screen_shake"] = _on_accessibility_changed.bind("screen_shake")
	_shake_slider.value_changed.connect(_bound_callables["screen_shake"])
	_bound_callables["cvd_sim"] = _on_accessibility_changed.bind("cvd_sim")
	_cvd_option.item_selected.connect(_bound_callables["cvd_sim"])

	_bound_callables["input_hints"] = _on_controls_changed.bind("input_hints")
	_input_hints_option.item_selected.connect(_bound_callables["input_hints"])

	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func _on_audio_changed(value: Variant, key: String) -> void:
	var sm: _SettingsManager = AutoloadHelper.settings_manager()
	if sm != null:
		var settings: Dictionary = sm.get("settings")
		if settings.has("audio"):
			settings["audio"][key] = value
			sm.apply_audio_settings()


func _on_apply_video_settings() -> void:
	var am: _UIAudioManager = AutoloadHelper.ui_audio_manager()
	if am:
		am.playUiSound("apply")
	var hm: _HapticsManager = AutoloadHelper.haptics_manager()
	if hm:
		hm.triggerHaptic("apply")

	var sm := AutoloadHelper.settings_manager()
	if sm == null:
		return
	var idx: int = _resolution_option.selected
	var s: Dictionary = sm.settings
	if not s.has("video"):
		return

	if idx >= 0 and idx < _resolutions.size():
		var res: Vector2i = _resolutions[idx]
		s["video"]["resolution_width"] = res.x
		s["video"]["resolution_height"] = res.y
	s["video"]["fullscreen"] = _fullscreen_check.button_pressed
	s["video"]["vsync"] = _vsync_check.button_pressed
	sm.apply_video_settings()
	sm.save_settings()


func _on_accessibility_changed(value: Variant, key: String) -> void:
	var sm := AutoloadHelper.settings_manager()
	if sm != null:
		var s: Dictionary = sm.settings
		if s.has("accessibility"):
			s["accessibility"][key] = value
			sm.apply_accessibility_settings()


func _on_controls_changed(index: int, key: String) -> void:
	var sm := AutoloadHelper.settings_manager()
	if sm != null:
		var s: Dictionary = sm.settings
		if s.has("controls"):
			s["controls"][key] = index


func _on_reset_pressed() -> void:
	var scene: PackedScene = load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if scene:
		var modal := scene.instantiate() as _ConfirmModal
		if modal != null:
			modal.setup("CONFIRM_RESET_SETTINGS_TITLE", "CONFIRM_RESET_SETTINGS_BODY")
			modal.confirmed.connect(_on_reset_confirmed)
			var lm: _LayerManager = AutoloadHelper.layer_manager()
			if lm:
				lm.add_modal(modal)


func _style_tab_container() -> void:
	## Make the active tab visually distinct so players can tell which
	## settings category is selected. Uses bright accent for foreground
	## and muted dark for inactive tabs.
	if not _tab_container:
		return
	# Accent colour used elsewhere in the UI (yellow-gold)
	var active_bg: Color = Color(0.9, 0.75, 0.2)
	var active_fg: Color = Color(0.1, 0.1, 0.1)
	var inactive_bg: Color = Color(0.15, 0.15, 0.15)
	var inactive_fg: Color = Color(0.6, 0.6, 0.6)

	_tab_container.add_theme_color_override("font_selected_color", active_fg)
	_tab_container.add_theme_color_override("font_unselected_color", inactive_fg)
	_tab_container.add_theme_color_override("tab_selected", active_bg)
	_tab_container.add_theme_color_override("tab_unselected", inactive_bg)

	# Listen to tab changes and force a restyle so Godot re-applies overrides.
	if not _tab_container.tab_changed.is_connected(_on_tab_changed):
		_tab_container.tab_changed.connect(_on_tab_changed)


func _on_tab_changed(_idx: int) -> void:
	# Force immediate redraw so theme overrides take effect on the new active tab.
	if _tab_container:
		_tab_container.queue_redraw()


func _on_reset_confirmed() -> void:
	var sm: _SettingsManager = AutoloadHelper.settings_manager()
	if sm != null:
		sm.reset_to_defaults()
		_load_ui_from_settings()


func _setupHelpListeners() -> void:
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

	for control: Control in controls:
		var bound_hover := _onControlHovered.bind(control.name)
		_bound_callables["hover_" + control.name] = bound_hover
		control.mouse_entered.connect(bound_hover)
		control.focus_entered.connect(bound_hover)
		control.mouse_exited.connect(_clearHelpText)
		control.focus_exited.connect(_clearHelpText)

		if control is Button or control is CheckBox or control is OptionButton:
			if control.has_signal("pressed"):
				control.pressed.connect(_onControlClicked)
			elif control.has_signal("item_selected"):
				control.item_selected.connect(_onControlClicked)
		elif control is HSlider:
			control.drag_ended.connect(_onControlClicked)


func _onControlHovered(control_name: String) -> void:
	_updateHelpText(control_name)
	var am: _UIAudioManager = AutoloadHelper.ui_audio_manager()
	if am:
		am.playUiSound("hover")
	var hm: _HapticsManager = AutoloadHelper.haptics_manager()
	if hm:
		hm.triggerHaptic("hover")


func _onControlClicked(_extra: Variant = null) -> void:
	var am: _UIAudioManager = AutoloadHelper.ui_audio_manager()
	if am:
		am.playUiSound("click")
	var hm: _HapticsManager = AutoloadHelper.haptics_manager()
	if hm:
		hm.triggerHaptic("click")


func _updateHelpText(control_name: String) -> void:
	if settingsHelp.has(control_name):
		helpLabel.text = tr(settingsHelp[control_name])


func _clearHelpText() -> void:
	helpLabel.text = " "


func _on_back_pressed() -> void:
	var am: _UIAudioManager = AutoloadHelper.ui_audio_manager()
	if am:
		am.playUiSound("cancel")
	var hm: _HapticsManager = AutoloadHelper.haptics_manager()
	if hm:
		hm.triggerHaptic("cancel")

	var sm: _SettingsManager = AutoloadHelper.settings_manager()
	if sm != null:
		sm.sync_bindings_to_settings()
		sm.save_settings()
	back_pressed.emit()
	hide()


func _on_safe_area_changed(_rect: Rect2) -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	var sz: _SafeZoneManager = AutoloadHelper.safe_zone_manager()
	if sz == null:
		return
	var margins: Dictionary = sz.get_safe_margins() as Dictionary
	_margin_container.add_theme_constant_override("margin_left", int(margins.get("left", 0)))
	_margin_container.add_theme_constant_override("margin_top", int(margins.get("top", 0)))
	_margin_container.add_theme_constant_override("margin_right", int(margins.get("right", 0)))
	_margin_container.add_theme_constant_override("margin_bottom", int(margins.get("bottom", 0)))
