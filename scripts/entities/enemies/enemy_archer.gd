class_name EnemyArcher
extends BaseEnemy


func _setup_entity() -> void:
	var cur_x: int = 0
	var cur_y: int = 0
	if entity:
		cur_x = entity.x
		cur_y = entity.y

	entity = Entity.new("UNIT_ARCHER", cur_x, cur_y, 25, 6, 2)
	entity.is_player = false
	entity.spd = 5


func _setup_ai() -> void:
	var controller: EnemyAIController = ai_controller as EnemyAIController
	if controller:
		controller.behavior = EnemyAIController.BehaviorType.ARCHER
