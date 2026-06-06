class_name AutoloadHelper
## Static helpers for safely retrieving autoload singletons at any point in the
## scene lifecycle, including during _init() and early _ready() calls where the
## autoload order cannot be guaranteed.
##
## Usage:
##   var cfg: Node = AutoloadHelper.config_loader()
##   var val: int  = AutoloadHelper.config_int("MY_KEY", 42)
##
## All methods return null / the fallback value if the autoload is not yet
## available — callers must always null-check the returned Node.
##
## Reference: audit improvement #15 — deduplicate _config_node() / _burden_node()
## pattern that was duplicated across entity_lifecycle.gd, burden_manager.gd,
## elemental_resolver.gd, burden_caption_bridge.gd, and burden_stem_caption_router.gd.

# ── Core Accessor ─────────────────────────────────────────────────────────────


## Returns the named autoload Node, or null if the SceneTree is not ready or
## the autoload has not been registered.
## Autoloads are always direct children of the scene root.
static func get_autoload(autoload_name: String) -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	if not ml is SceneTree:
		return null
	var tree: SceneTree = ml as SceneTree
	if tree.root == null or not tree.root.is_inside_tree():
		return null
	return tree.root.get_node_or_null(autoload_name)


# ── Named Autoload Shortcuts ──────────────────────────────────────────────────


## Returns the ConfigLoader autoload, or null.
static func config_loader() -> _ConfigLoader:
	return get_autoload("ConfigLoader") as _ConfigLoader


## Returns the BurdenManager autoload, or null.
static func burden_manager() -> _BurdenManager:
	return get_autoload("BurdenManager") as _BurdenManager


## Returns the CaptionManager autoload, or null.
static func caption_manager() -> _CaptionManager:
	return get_autoload("CaptionManager") as _CaptionManager


## Returns the EntityLifecycle autoload, or null.
static func entity_lifecycle() -> _EntityLifecycle:
	return get_autoload("EntityLifecycle") as _EntityLifecycle


## Returns the RunManager autoload, or null.
static func run_manager() -> _RunManager:
	return get_autoload("RunManager") as _RunManager


## Returns the CodexManager autoload, or null.
static func codex_manager() -> _CodexManager:
	return get_autoload("CodexManager") as _CodexManager


## Returns the EventBus autoload, or null.
static func event_bus() -> _EventBus:
	return get_autoload("EventBus") as _EventBus


## Returns the SaveManager autoload, or null.
static func save_manager() -> _SaveManager:
	return get_autoload("SaveManager") as _SaveManager


## Returns the TutorialManager autoload, or null.
static func tutorial_manager() -> _TutorialManager:
	return get_autoload("TutorialManager") as _TutorialManager


## Returns the GridSystem autoload, or null.
static func grid_system() -> _GridSystem:
	return get_autoload("GridSystem") as _GridSystem


## Returns the SettingsManager autoload, or null.
## NOTE: Returns Node instead of _SettingsManager to prevent engine Parse Errors
## and circularities in headless Godot environments.
static func settings_manager() -> Node:
	return get_autoload("SettingsManager")


## Returns the LocalizationManager autoload, or null.
## NOTE: Returns Node instead of _LocalizationManager to prevent engine Parse Errors
## and circularities in headless Godot environments where class_name resolution
## may fail during early initialization.
static func localization_manager() -> Node:
	return get_autoload("LocalizationManager")


# ── Derived Helpers ───────────────────────────────────────────────────────────


## Reads an int config value via ConfigLoader.get_int(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
static func config_int(key: String, fallback: int) -> int:
	var n: Node = config_loader()
	if n != null and n.has_method("get_int"):
		return n.get_int(key, fallback)
	return fallback


## Reads a float config value via ConfigLoader.get_float(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
static func config_float(key: String, fallback: float) -> float:
	var n: Node = config_loader()
	if n != null and n.has_method("get_float"):
		return n.get_float(key, fallback)
	return fallback


## Reads a String config value via ConfigLoader.get_string(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
static func config_string(key: String, fallback: String) -> String:
	var n: Node = config_loader()
	if n != null and n.has_method("get_string"):
		return n.get_string(key, fallback)
	return fallback
