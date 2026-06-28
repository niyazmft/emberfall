class_name _SteamManager
extends Node
## Steamworks API wrapper with graceful offline fallbacks.
## Provides Cloud Save sync, Achievement unlock, and Rich Presence.

signal achievement_unlocked(achievement_id: String)
signal cloud_save_synced(success: bool)

var _steam_available: bool = false
var _steam_initialized: bool = false

## Steam app ID for Emberfall (replace with actual ID when publishing)
const STEAM_APP_ID: int = 480  # 480 = Spacewar (Steam test app)


func _ready() -> void:
	## Attempt to initialize Steamworks. If GodotSteam is not installed
	## or Steam is not running, silently fall back to offline mode.
	_steam_available = _detect_steam()
	if _steam_available:
		_steam_initialized = _init_steam()
		if _steam_initialized:
			push_warning("[SteamManager] Steamworks initialized successfully.")
		else:
			push_warning("[SteamManager] Steamworks detection succeeded but init failed.")
	else:
		if OS.is_debug_build():
			push_warning("[SteamManager] Steamworks not available. Running in offline mode.")


func _detect_steam() -> bool:
	## Check if GodotSteam GDExtension classes are available.
	## Uses ClassDB to avoid compile-time dependency on the extension.
	return ClassDB.class_exists("Steam")


func _init_steam() -> bool:
	## Attempt to call Steam.init() via Callable to avoid script parse errors
	## when GodotSteam is not present.
	var steam_singleton: Object = Engine.get_singleton("Steam")
	if steam_singleton == null:
		return false
	var init_callable: Callable = Callable(steam_singleton, "init")
	if not init_callable.is_valid():
		return false
	var result: bool = init_callable.call(STEAM_APP_ID)
	return result


## ------------------------------------------------------------------
## Cloud Saves
## ------------------------------------------------------------------


func sync_cloud_save(local_path: String, remote_name: String) -> bool:
	if not _steam_initialized:
		return false
	var steam: Object = Engine.get_singleton("Steam")
	if steam == null:
		return false
	var write_callable: Callable = Callable(steam, "fileWrite")
	if not write_callable.is_valid():
		return false
	var file: FileAccess = FileAccess.open(local_path, FileAccess.READ)
	if file == null:
		return false
	var data: PackedByteArray = file.get_buffer(file.get_length())
	var success: bool = write_callable.call(remote_name, data)
	cloud_save_synced.emit(success)
	return success


func read_cloud_save(remote_name: String, local_path: String) -> bool:
	if not _steam_initialized:
		return false
	var steam: Object = Engine.get_singleton("Steam")
	if steam == null:
		return false
	var read_callable: Callable = Callable(steam, "fileRead")
	if not read_callable.is_valid():
		return false
	var data: PackedByteArray = read_callable.call(remote_name)
	if data.is_empty():
		return false
	var file: FileAccess = FileAccess.open(local_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(data)
	return true


## ------------------------------------------------------------------
## Achievements
## ------------------------------------------------------------------


func unlock_achievement(achievement_id: String) -> void:
	if not _steam_initialized:
		return
	var steam: Object = Engine.get_singleton("Steam")
	if steam == null:
		return
	var set_achv: Callable = Callable(steam, "setAchievement")
	if not set_achv.is_valid():
		return
	set_achv.call(achievement_id)
	var store_callable: Callable = Callable(steam, "storeStats")
	if store_callable.is_valid():
		store_callable.call()
	achievement_unlocked.emit(achievement_id)


func is_achievement_unlocked(achievement_id: String) -> bool:
	if not _steam_initialized:
		return false
	var steam: Object = Engine.get_singleton("Steam")
	if steam == null:
		return false
	var get_achv: Callable = Callable(steam, "getAchievement")
	if not get_achv.is_valid():
		return false
	var result: Variant = get_achv.call(achievement_id)
	# getAchievement returns a Dictionary with "achieved" key
	if result is Dictionary:
		return result.get("achieved", false)
	return false


## ------------------------------------------------------------------
## Rich Presence
## ------------------------------------------------------------------


func set_rich_presence(key: String, value: String) -> void:
	if not _steam_initialized:
		return
	var steam: Object = Engine.get_singleton("Steam")
	if steam == null:
		return
	var set_presence: Callable = Callable(steam, "setRichPresence")
	if not set_presence.is_valid():
		return
	set_presence.call(key, value)


## ------------------------------------------------------------------
## Query
## ------------------------------------------------------------------


func is_steam_available() -> bool:
	return _steam_available


func is_steam_initialized() -> bool:
	return _steam_initialized
