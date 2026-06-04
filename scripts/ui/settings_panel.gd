extends Control

## SettingsPanel
## Manages UI for game settings.

signal back_pressed

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
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton

var _resolutions: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1024, 576),
]


func _ready() -> void:
	_setup_options()
	_load_ui_from_settings()
	_connect_signals()


func _setup_options() -> void:
	_resolution_option.clear()
	for res in _resolutions:
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
	var s: Dictionary = SettingsManager.settings

	# Audio
	_master_slider.value = s.audio.master_volume
	_music_slider.value = s.audio.music_volume
	_sfx_slider.value = s.audio.sfx_volume
	_mute_check.button_pressed = s.audio.get("mute", false)

	# Video
	var current_res := Vector2i(
		s.video.get("resolution_width", 1920), s.video.get("resolution_height", 1080)
	)
	var res_index := _resolutions.find(current_res)
	if res_index != -1:
		_resolution_option.selected = res_index

	_fullscreen_check.button_pressed = s.video.fullscreen
	_vsync_check.button_pressed = s.video.get("vsync", true)

	# Accessibility
	_shake_slider.value = s.accessibility.screen_shake
	_cvd_option.selected = s.accessibility.get("cvd_sim", 0)

	# Controls
	_input_hints_option.selected = s.controls.input_hints


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
	SettingsManager.settings.audio[key] = value
	SettingsManager.apply_settings()


func _on_apply_video_settings() -> void:
	var res := _resolutions[_resolution_option.selected]
	SettingsManager.settings.video.resolution_width = res.x
	SettingsManager.settings.video.resolution_height = res.y
	SettingsManager.settings.video.fullscreen = _fullscreen_check.button_pressed
	SettingsManager.settings.video.vsync = _vsync_check.button_pressed
	SettingsManager.apply_settings()
	SettingsManager.save_settings()


func _on_accessibility_changed(value: Variant, key: String) -> void:
	SettingsManager.settings.accessibility[key] = value
	SettingsManager.apply_settings()


func _on_controls_changed(index: int, key: String) -> void:
	SettingsManager.settings.controls[key] = index
	SettingsManager.apply_settings()


func _on_reset_pressed() -> void:
	var scene: PackedScene = load("res://scenes/ui/confirm_modal.tscn") as PackedScene
	if scene:
		var modal: Node = scene.instantiate()
		modal.call("setup", "CONFIRM_RESET_TITLE", "CONFIRM_RESET_BODY")
		modal.connect("confirmed", _on_reset_confirmed)
		LayerManager.add_modal(modal)


func _on_reset_confirmed() -> void:
	SettingsManager.reset_to_defaults()
	_load_ui_from_settings()


func _on_back_pressed() -> void:
	SettingsManager.save_settings()
	back_pressed.emit()
	hide()
