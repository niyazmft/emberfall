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


## Returns the LevelUpManager autoload, or null.
static func level_up_manager() -> _LevelUpManager:
	return get_autoload("LevelUpManager") as _LevelUpManager


## Returns the RunManager autoload, or null.
static func run_manager() -> _RunManager:
	return get_autoload("RunManager") as _RunManager


## Returns the EventBus autoload, or null.
static func event_bus() -> _EventBus:
	return get_autoload("EventBus") as _EventBus


## Returns the SaveManager autoload, or null.
static func save_manager() -> _SaveManager:
	return get_autoload("SaveManager") as _SaveManager


## Returns the GridSystem autoload, or null.
static func grid_system() -> _GridSystem:
	return get_autoload("GridSystem") as _GridSystem


## Returns the InventoryManager autoload, or null.
static func inventory_manager() -> Node:
	return get_autoload("InventoryManager")


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


## Returns the AmbientNarrator autoload, or null.
static func ambient_narrator() -> _AmbientNarrator:
	return get_autoload("AmbientNarrator") as _AmbientNarrator


## Returns the SecretRoomTrigger autoload, or null.
static func secret_room_trigger() -> _SecretRoomTrigger:
	return get_autoload("SecretRoomTrigger") as _SecretRoomTrigger


# ── Derived Helpers ───────────────────────────────────────────────────────────


## Reads an int config value via ConfigLoader.getInt(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
## Supports both (key, fallback) and (section, key, fallback) signatures.
static func config_int(arg1: String, arg2: Variant = null, arg3: Variant = null) -> int:
	var n: Node = config_loader()
	if n != null and n.has_method("getInt"):
		return n.getInt(arg1, arg2, arg3)
	if arg2 is String:
		return int(arg3) if arg3 != null else 0
	return int(arg2) if arg2 != null else 0


## Reads a float config value via ConfigLoader.getFloat(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
## Supports both (key, fallback) and (section, key, fallback) signatures.
static func config_float(arg1: String, arg2: Variant = null, arg3: Variant = null) -> float:
	var n: Node = config_loader()
	if n != null and n.has_method("getFloat"):
		return n.getFloat(arg1, arg2, arg3)
	if arg2 is String:
		return float(arg3) if arg3 != null else 0.0
	return float(arg2) if arg2 != null else 0.0


## Reads a String config value via ConfigLoader.getString(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
## Supports both (key, fallback) and (section, key, fallback) signatures.
static func config_string(arg1: String, arg2: Variant = null, arg3: Variant = null) -> String:
	var n: Node = config_loader()
	if n != null and n.has_method("getString"):
		return n.getString(arg1, arg2, arg3)
	if arg2 is String:
		return str(arg3) if arg3 != null else ""
	return str(arg2) if arg2 != null else ""
