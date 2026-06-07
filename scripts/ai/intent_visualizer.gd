class_name IntentVisualizer
extends Node
## IntentVisualizer
## Visualizes enemy intents (movement, attacks) using GridRenderer.

var _gridRenderer: GridRenderer
var _configLoader: _ConfigLoader


func _init(pGridRenderer: GridRenderer) -> void:
	_gridRenderer = pGridRenderer
	_configLoader = AutoloadHelper.config_loader()


## Visualize the intended action of an enemy.
func visualizeIntent(enemy: Entity, action: Dictionary) -> void:
	if not _gridRenderer or not _configLoader:
		return

	var actionType: String = str(action.get("type", ""))
	match actionType:
		"move":
			var targetX: int = int(action.get("target_x", enemy.x))
			var targetY: int = int(action.get("target_y", enemy.y))
			_gridRenderer.highlight_tile_styled(targetX, targetY, "telegraph")
			_gridRenderer.draw_telegraph_arrow(Vector2i(enemy.x, enemy.y), Vector2i(targetX, targetY))

		"attack":
			var targetNodeRef: Variant = action.get("target")
			if targetNodeRef is Node2D:
				var targetNode: Node2D = targetNodeRef as Node2D
				var targetEntRef: Variant = targetNode.get("entity")
				if targetEntRef is Entity:
					var targetEnt: Entity = targetEntRef as Entity
					_gridRenderer.highlight_tile_styled(targetEnt.x, targetEnt.y, "telegraph")
					_gridRenderer.draw_telegraph_arrow(Vector2i(enemy.x, enemy.y), Vector2i(targetEnt.x, targetEnt.y))


## Clear all visualized intents.
func clearIntents() -> void:
	if _gridRenderer:
		_gridRenderer.clear_highlights_styled("telegraph")
		_gridRenderer.clear_telegraphs()
