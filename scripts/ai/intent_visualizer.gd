class_name IntentVisualizer
extends Node
## IntentVisualizer
## Visualizes enemy intents (movement, attacks) using GridRenderer.

var _grid_renderer: GridRenderer
var _config_loader: _ConfigLoader


func _init(p_grid_renderer: GridRenderer) -> void:
	_grid_renderer = p_grid_renderer
	_config_loader = AutoloadHelper.config_loader()


## Visualize the intended action of an enemy.
func visualize_intent(enemy: Entity, action: Dictionary) -> void:
	if not _grid_renderer or not _config_loader:
		return

	match action.get("type"):
		"move":
			var tx: int = action.get("target_x", enemy.x)
			var ty: int = action.get("target_y", enemy.y)
			_grid_renderer.highlight_tile_styled(tx, ty, "telegraph")
			_grid_renderer.draw_telegraph_arrow(Vector2i(enemy.x, enemy.y), Vector2i(tx, ty))

		"attack":
			var target_node: Node2D = action.get("target")
			if target_node:
				var target_ent: Entity = target_node.get("entity") as Entity
				if target_ent:
					_grid_renderer.highlight_tile_styled(target_ent.x, target_ent.y, "telegraph")
					_grid_renderer.draw_telegraph_arrow(Vector2i(enemy.x, enemy.y), Vector2i(target_ent.x, target_ent.y))


## Clear all visualized intents.
func clear_intents() -> void:
	if _grid_renderer:
		_grid_renderer.clear_highlights_styled("telegraph")
		_grid_renderer.clear_telegraphs()
