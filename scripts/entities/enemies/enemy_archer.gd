class_name EnemyArcher
extends BaseEnemy


func get_archetype_id() -> String:
	return "archer"


func _init() -> void:
	archetype_id = "archer"
