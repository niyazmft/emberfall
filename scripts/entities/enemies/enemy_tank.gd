class_name EnemyTank
extends BaseEnemy


func _setup_entity() -> void:
	var cur_x := 0
	var cur_y := 0
	if entity:
		cur_x = entity.x
		cur_y = entity.y

	entity = Entity.new("Tank", cur_x, cur_y, 60, 15, 8)
	entity.is_player = false
	entity.spd = 2


func _setup_ai() -> void:
	var controller := ai_controller as EnemyAIController
	if controller:
		controller.behavior = EnemyAIController.BehaviorType.TANK
