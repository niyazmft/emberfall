extends Control

## SettingsPanel
## Manages UI for game settings.

signal back_pressed

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _fullscreen_check: CheckBox = %FullscreenCheck
@onready var _shake_slider: HSlider = %ShakeSlider
@onready var _input_hints_option: OptionButton = %InputHintsOption
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_load_ui_from_settings()
	_connect_signals()


func _load_ui_from_settings() -> void:
	var s: Dictionary = SettingsManager.settings
	_master_slider.value = s.audio.master_volume
	_music_slider.value = s.audio.music_volume
	_sfx_slider.value = s.audio.sfx_volume
	_fullscreen_check.button_pressed = s.video.fullscreen
	_shake_slider.value = s.accessibility.screen_shake

	_input_hints_option.clear()
	_input_hints_option.add_item(tr("OPTION_AUTO"), 0)
	_input_hints_option.add_item(tr("OPTION_KBM"), 1)
	_input_hints_option.add_item(tr("OPTION_GP"), 2)
	_input_hints_option.selected = s.controls.input_hints


func _connect_signals() -> void:
	_master_slider.value_changed.connect(_on_audio_changed.bind("master_volume"))
	_music_slider.value_changed.connect(_on_audio_changed.bind("music_volume"))
	_sfx_slider.value_changed.connect(_on_audio_changed.bind("sfx_volume"))
	_fullscreen_check.toggled.connect(_on_video_changed.bind("fullscreen"))
	_shake_slider.value_changed.connect(_on_accessibility_changed.bind("screen_shake"))
	_input_hints_option.item_selected.connect(_on_controls_changed.bind("input_hints"))
	_back_button.pressed.connect(_on_back_pressed)


func _on_audio_changed(value: float, key: String) -> void:
	SettingsManager.settings.audio[key] = value
	SettingsManager.apply_settings()


func _on_video_changed(value: bool, key: String) -> void:
	SettingsManager.settings.video[key] = value
	SettingsManager.apply_settings()


func _on_accessibility_changed(value: float, key: String) -> void:
	SettingsManager.settings.accessibility[key] = value
	SettingsManager.apply_settings()


func _on_controls_changed(index: int, key: String) -> void:
	SettingsManager.settings.controls[key] = index
	SettingsManager.apply_settings()


func _on_back_pressed() -> void:
	SettingsManager.save_settings()
	back_pressed.emit()
	hide()
