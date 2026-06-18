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


## Returns the BurdenShaderManager autoload, or null.
static func burden_shader_manager() -> _BurdenShaderManager:
	return get_autoload("BurdenShaderManager") as _BurdenShaderManager


## Returns the InventoryManager autoload, or null.
static func inventory_manager() -> _InventoryManager:
	return get_autoload("InventoryManager") as _InventoryManager


## Returns the SettingsManager autoload, or null.
static func settings_manager() -> _SettingsManager:
	return get_autoload("SettingsManager") as _SettingsManager


## Returns the LocalizationManager autoload, or null.
static func localization_manager() -> _LocalizationManager:
	return get_autoload("LocalizationManager") as _LocalizationManager


## Returns the AmbientNarrator autoload, or null.
static func ambient_narrator() -> _AmbientNarrator:
	return get_autoload("AmbientNarrator") as _AmbientNarrator


## Returns the SecretRoomTrigger autoload, or null.
static func secret_room_trigger() -> _SecretRoomTrigger:
	return get_autoload("SecretRoomTrigger") as _SecretRoomTrigger


## Returns the GameCoordinator autoload, or null.
static func game_coordinator() -> _GameCoordinator:
	return get_autoload("GameCoordinator") as _GameCoordinator


## Returns the SafeZoneManager autoload, or null.
static func safe_zone_manager() -> _SafeZoneManager:
	return get_autoload("SafeZoneManager") as _SafeZoneManager


## Returns the LayerManager autoload, or null.
static func layer_manager() -> _LayerManager:
	return get_autoload("LayerManager") as _LayerManager


## Returns the InputRouter autoload, or null.
static func input_router() -> _InputRouter:
	return get_autoload("InputRouter") as _InputRouter


## Returns the AudioMiddleware autoload, or null.
static func audio_middleware() -> _AudioMiddleware:
	return get_autoload("AudioMiddleware") as _AudioMiddleware


## Returns the AbilityManager autoload, or null.
static func ability_manager() -> _AbilityManager:
	return get_autoload("AbilityManager") as _AbilityManager


## Returns the BurdenCaptionDriver autoload, or null.
static func burden_caption_driver() -> _BurdenCaptionDriver:
	return get_autoload("BurdenCaptionDriver") as _BurdenCaptionDriver


## Returns the BurdenEventCoordinator autoload, or null.
static func burden_event_coordinator() -> _BurdenEventCoordinator:
	return get_autoload("BurdenEventCoordinator") as _BurdenEventCoordinator


## Returns the ToastManager autoload, or null.
static func toast_manager() -> _ToastManager:
	return get_autoload("ToastManager") as _ToastManager


## Returns the FocusManager autoload, or null.
static func focus_manager() -> _FocusManager:
	return get_autoload("FocusManager") as _FocusManager


## Returns the UIAudioManager autoload, or null.
static func ui_audio_manager() -> _UIAudioManager:
	return get_autoload("UIAudioManager") as _UIAudioManager


## Returns the HapticsManager autoload, or null.
static func haptics_manager() -> _HapticsManager:
	return get_autoload("HapticsManager") as _HapticsManager


# ── Derived Helpers ───────────────────────────────────────────────────────────


## Reads an int config value via ConfigLoader.get_int(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
static func config_int(key: String, fallback: int) -> int:
	var n: _ConfigLoader = config_loader()
	if n != null:
		return n.getInt(key, fallback)
	return fallback


## Reads a float config value via ConfigLoader.get_float(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
static func config_float(key: String, fallback: float) -> float:
	var n: _ConfigLoader = config_loader()
	if n != null:
		return n.getFloat(key, fallback)
	return fallback


## Reads a String config value via ConfigLoader.get_string(), returning fallback
## if ConfigLoader is unavailable or the key is not set.
static func config_string(key: String, fallback: String) -> String:
	var n: _ConfigLoader = config_loader()
	if n != null:
		return n.getString(key, fallback)
	return fallback
