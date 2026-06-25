class_name _DialogueManager
extends Node

## Minimal dialogue system for character dialogue and internal monologue.
## Uses the localization system for text lookup.

const DIALOGUE_SCENE_PATH := "res://scenes/ui/dialogue_box.tscn"

var _dialogue_box: Control
var _label: Label
var _is_visible: bool = false


func _ready() -> void:
	_load_dialogue_box()


func _load_dialogue_box() -> void:
	var scene: PackedScene = load(DIALOGUE_SCENE_PATH) as PackedScene
	if scene == null:
		push_warning("DialogueManager: failed to load dialogue box scene")
		return
	_dialogue_box = scene.instantiate() as Control
	if _dialogue_box == null:
		push_warning("DialogueManager: failed to instantiate dialogue box")
		return
	_label = _dialogue_box.get_node_or_null("Panel/Label") as Label
	if _label == null:
		_label = _dialogue_box.find_child("Label", true, false) as Label
	_dialogue_box.visible = false
	var ui_layer: CanvasLayer = _get_ui_layer()
	if ui_layer != null:
		ui_layer.add_child(_dialogue_box)
	else:
		add_child(_dialogue_box)


func _get_ui_layer() -> CanvasLayer:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var current_scene := tree.current_scene
	if current_scene == null:
		return null
	for child: Node in current_scene.get_children():
		if child is CanvasLayer:
			return child as CanvasLayer
	return null


## Show a spoken dialogue line with the given localization key.
## Displays in normal (non-italic) text with a speaker box.
func show_dialogue(key: String) -> void:
	if _dialogue_box == null:
		return
	var text: String = tr(key)
	if text.is_empty():
		text = key
	_set_text(text, false)
	_dialogue_box.visible = true
	_is_visible = true


## Show internal monologue (italicized, no speaker name).
## Positioned at bottom of screen with a subtle style.
func show_internal_monologue(key: String) -> void:
	if _dialogue_box == null:
		return
	var text: String = tr(key)
	if text.is_empty():
		text = key
	_set_text(text, true)
	_dialogue_box.visible = true
	_is_visible = true


## Hide the dialogue box.
func dismiss() -> void:
	if _dialogue_box == null:
		return
	_dialogue_box.visible = false
	_is_visible = false


func _set_text(text: String, is_italic: bool) -> void:
	if _label == null:
		return
	_label.text = text
	if is_italic:
		_label.add_theme_font_override("font", _get_italic_font())
	else:
		_label.remove_theme_font_override("font")


func _get_italic_font() -> Font:
	## Fallback: return the default project font (no true italic available).
	## The text style is conveyed via the dialogue box background.
	return ThemeDB.get_project_theme().default_font if ThemeDB.get_project_theme() != null else null
