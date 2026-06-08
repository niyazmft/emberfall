class_name EnemyMage
extends BaseEnemy


func get_archetype_id() -> String:
	return "mage"


func _init() -> void:
	archetype_id = "mage"
