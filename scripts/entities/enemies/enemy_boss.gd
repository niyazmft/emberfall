class_name EnemyBoss
extends BaseEnemy


func get_archetype_id() -> String:
	return "boss"


func _init() -> void:
	archetype_id = "boss"
