class_name EnemyGrunt
extends BaseEnemy


func get_archetype_id() -> String:
	return "grunt"


func _init() -> void:
	archetype_id = "grunt"
