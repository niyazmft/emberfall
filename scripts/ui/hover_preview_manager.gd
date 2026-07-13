class_name HoverPreviewManager
extends Control
## HoverPreviewManager
## Shows deterministic combat preview when hovering enemies or tiles.
## Color-codes severity: green (safe), yellow (moderate), red (lethal).

const PANEL_BG := Color(0.08, 0.08, 0.12, 0.92)
const COLOR_SAFE := Color(0.4, 0.9, 0.4, 1.0)
const COLOR_WARNING := Color(0.95, 0.75, 0.2, 1.0)
const COLOR_DANGER := Color(0.9, 0.25, 0.2, 1.0)
const COLOR_INFO := Color(0.7, 0.7, 0.8, 1.0)

var _panel: PanelContainer
var _title_label: Label
var _detail_label: Label
var _player_entity: Entity
var _grid_system: _GridSystem


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(180, 0)
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.4, 0.8)
	_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_title_label)

	_detail_label = Label.new()
	_detail_label.add_theme_font_size_override("font_size", 11)
	_detail_label.add_theme_color_override("font_color", COLOR_INFO)
	vbox.add_child(_detail_label)


func setup(player: Entity) -> void:
	_player_entity = player
	_grid_system = AutoloadHelper.grid_system()


func clear() -> void:
	hide()
	_title_label.text = ""
	_detail_label.text = ""


func show_enemy_preview(enemy_ent: Entity, enemy_name: String) -> void:
	if not _player_entity:
		return

	var cover_tiles: Array[Vector2i] = _get_cover_tiles()
	var damage: int = CombatFormula.compute_damage_from_entities(
		_player_entity, enemy_ent, cover_tiles
	)
	var hp_after: int = maxi(0, enemy_ent.hp - damage)
	var hp_pct: float = float(enemy_ent.hp) / float(max(1, enemy_ent.hp_max))

	_title_label.text = "%s" % enemy_name
	_title_label.add_theme_color_override(
		"font_color", _severity_color(hp_pct, damage, enemy_ent.hp)
	)

	var lines: Array[String] = []
	lines.append("Attack: %d dmg" % damage)
	lines.append("HP: %d / %d → %d" % [enemy_ent.hp, enemy_ent.hp_max, hp_after])

	var cost: int = CombatFormula.action_cost("attack_basic")
	if _player_entity.ap >= cost:
		lines.append("AP cost: %d" % cost)
	else:
		lines.append("Not enough AP (%d / %d)" % [_player_entity.ap, cost])

	_detail_label.text = "\n".join(lines)
	_position_at_mouse()
	show()


func show_tile_preview(tile: TacTileData, has_enemy: bool) -> void:
	if not _player_entity:
		return

	var lines: Array[String] = []
	var cost: int = CombatFormula.action_cost("move_cardinal")

	if (
		_grid_system
		and _grid_system.can_move(_player_entity.x, _player_entity.y, tile.coords.x, tile.coords.y)
	):
		if _player_entity.ap >= cost:
			lines.append("Move: %d AP" % cost)
		else:
			lines.append("Move: %d AP (not enough)" % cost)
	elif tile.has_cover():
		lines.append("Cover: +defence")
	elif tile.elevation > 0:
		lines.append("Elevation: +%d" % tile.elevation)

	if lines.is_empty():
		clear()
		return

	_title_label.text = "Tile (%d, %d)" % [tile.coords.x, tile.coords.y]
	_title_label.add_theme_color_override("font_color", COLOR_INFO)
	_detail_label.text = "\n".join(lines)
	_position_at_mouse()
	show()


func _position_at_mouse() -> void:
	var mouse: Vector2 = get_global_mouse_position()
	var pad: float = 16.0
	_panel.position = Vector2(mouse.x + pad, mouse.y + pad)

	# Keep inside viewport
	var viewport: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = _panel.size
	if _panel.position.x + panel_size.x > viewport.x:
		_panel.position.x = mouse.x - panel_size.x - pad
	if _panel.position.y + panel_size.y > viewport.y:
		_panel.position.y = mouse.y - panel_size.y - pad


func _get_cover_tiles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if _grid_system:
		var all_tiles: Array[TacTileData] = _grid_system.all_tiles()
		for t: TacTileData in all_tiles:
			if t.has_cover():
				out.append(t.coords)
	return out


func _severity_color(hp_pct: float, damage: int, current_hp: int) -> Color:
	if damage >= current_hp:
		return COLOR_DANGER
	if hp_pct <= 0.3 or damage >= current_hp * 0.5:
		return COLOR_WARNING
	return COLOR_SAFE
