class_name CombatEntity
extends Node2D
## Base class for all entities that participate in combat and have an Entity data block.

@export var entity: Entity


## Returns the Entity resource from a Node if it is a CombatEntity, otherwise null.
static func get_entity(node: Node) -> Entity:
	if node is CombatEntity:
		return (node as CombatEntity).entity
	return null
