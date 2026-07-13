class_name ActionHistory
extends RefCounted
## ActionHistory
## Manages a LIFO stack of state snapshots for undo/rewind.
## Stores one snapshot per player action within the current turn.

## Signal emitted when undo is performed.
signal undo_performed(action_description: String)

var _snapshots: Array[Dictionary] = []
var _snapshot_limit: int = 0  # 0 = unlimited


func set_limit(limit: int) -> void:
	_snapshot_limit = maxi(0, limit)
	_trim_to_limit()


## Push a snapshot before a player action.
func push_snapshot(
	player_snapshot: Dictionary, enemy_snapshots: Array[Dictionary], action_description: String
) -> void:
	var snapshot: Dictionary = {
		"player": player_snapshot.duplicate(true),
		"enemies": enemy_snapshots.duplicate(true),
		"description": action_description,
	}
	_snapshots.append(snapshot)
	_trim_to_limit()


## Pop and return the most recent snapshot. Returns empty Dictionary if none.
func undo() -> Dictionary:
	if _snapshots.is_empty():
		return {}
	var snapshot: Dictionary = _snapshots.pop_back()
	undo_performed.emit(snapshot.get("description", ""))
	return snapshot


## Clear all snapshots (called when turn ends).
func clear() -> void:
	_snapshots.clear()


## Returns true if there are snapshots available to undo.
func can_undo() -> bool:
	return not _snapshots.is_empty()


## Returns the number of stored snapshots.
func size() -> int:
	return _snapshots.size()


## Serialize an Entity into a flat Dictionary.
static func serialize_entity(entity: Entity) -> Dictionary:
	return {
		"x": entity.x,
		"y": entity.y,
		"elevation": entity.elevation,
		"facing_x": entity.facing_x,
		"facing_y": entity.facing_y,
		"hp": entity.hp,
		"hp_max": entity.hp_max,
		"ap": entity.ap,
		"moral_flag": entity.moral_flag,
		"state": int(entity.state),
		"off": entity.off,
		"def_": entity.def_,
		"spd": entity.spd,
	}


## Restore an Entity from a serialized Dictionary.
static func restore_entity(entity: Entity, data: Dictionary) -> void:
	entity.x = int(data.get("x", 0))
	entity.y = int(data.get("y", 0))
	entity.elevation = int(data.get("elevation", 0))
	entity.facing_x = int(data.get("facing_x", 0))
	entity.facing_y = int(data.get("facing_y", 1))
	entity.hp = int(data.get("hp", 1))
	entity.hp_max = int(data.get("hp_max", 1))
	entity.ap = int(data.get("ap", 0))
	entity.moral_flag = int(data.get("moral_flag", 0))
	entity.state = int(data.get("state", 0)) as Entity.State
	entity.off = int(data.get("off", 0))
	entity.def_ = int(data.get("def_", 0))
	entity.spd = int(data.get("spd", 1))


func _trim_to_limit() -> void:
	if _snapshot_limit <= 0:
		return
	while _snapshots.size() > _snapshot_limit:
		_snapshots.remove_at(0)
