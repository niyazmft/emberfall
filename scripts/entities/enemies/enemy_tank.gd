class_name EnemyTank
extends BaseEnemy


func get_archetype_id() -> String:
	return "tank"


func _init() -> void:
	archetype_id = "tank"
