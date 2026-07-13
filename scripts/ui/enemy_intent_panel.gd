class_name EnemyIntentPanel
extends PanelContainer
## EnemyIntentPanel (FIX #601)
## Displays each enemy's planned action for the upcoming enemy turn.
## Sorted by threat level (lethal first). Refreshes at start of player turn.

const INTENT_BG_ATTACK: Color = Color(0.9, 0.15, 0.15, 0.85)  # Red
const INTENT_BG_MOVE: Color = Color(0.15, 0.5, 0.85, 0.85)  # Blue
const INTENT_BG_WAIT: Color = Color(0.4, 0.4, 0.4, 0.85)  # Gray
const INTENT_BG_AOE: Color = Color(0.85, 0.5, 0.15, 0.85)  # Orange
const TEXT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)

var _entries: Array[Dictionary] = []
var _enemy_nodes: Array[Node2D] = []
var _grid_system: _GridSystem = null

@onready var _flow: HBoxContainer = HBoxContainer.new()


func _ready() -> void:
	## Panel styling
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.92)
	panel_style.border_color = Color(0.25, 0.25, 0.3, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.corner_radius_bottom_left = 6
	add_theme_stylebox_override("panel", panel_style)

	## Layout
	_flow.alignment = BoxContainer.ALIGNMENT_CENTER
	_flow.add_theme_constant_override("separation", 8)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.add_child(_flow)
	add_child(margin)

	## Position at top of screen
	anchors_preset = Control.PRESET_TOP_WIDE
	position = Vector2(0, 8)
	custom_minimum_size = Vector2(200, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_grid_system = AutoloadHelper.grid_system()


## Call when player turn starts to refresh all enemy intents.
func refresh(enemy_nodes: Array[Node2D]) -> void:
	_enemy_nodes = enemy_nodes
	_clear_entries()
	_compute_intents()
	_sort_by_threat()
	_build_ui()


## Hide the panel (e.g. during enemy turn or when no enemies).
func clear() -> void:
	_clear_entries()
	_build_ui()
	visible = false


func _clear_entries() -> void:
	_entries.clear()
	for child: Node in _flow.get_children():
		_flow.remove_child(child)
		child.queue_free()


func _compute_intents() -> void:
	for enemy_node: Node2D in _enemy_nodes:
		if not is_instance_valid(enemy_node):
			continue
		if not enemy_node is BaseEnemy:
			continue

		var base_enemy: BaseEnemy = enemy_node as BaseEnemy
		if not base_enemy.entity or base_enemy.entity.hp <= 0:
			continue
		if base_enemy.entity.state == Entity.State.STUNNED:
			_entries.append(_make_entry(base_enemy, "wait", "Stunned", INTENT_BG_WAIT, 0))
			continue

		var controller: EnemyAIController = base_enemy.ai_controller as EnemyAIController
		if controller == null:
			continue

		var action: Dictionary = controller.decide_action(base_enemy.entity)
		var action_type: String = action.get("type", "wait")
		var is_aoe: bool = action.get("aoe", false)

		match action_type:
			"attack":
				var target: Node2D = action.get("target") as Node2D
				var target_name: String = _get_target_name(target)
				var threat: int = _calculate_threat(base_enemy, target, action)
				var bg: Color = INTENT_BG_AOE if is_aoe else INTENT_BG_ATTACK
				var label: String = "⚔ %s" % target_name if not is_aoe else "☠ %s" % target_name
				_entries.append(_make_entry(base_enemy, action_type, label, bg, threat))
			"move":
				var tx: int = action.get("target_x", base_enemy.entity.x)
				var ty: int = action.get("target_y", base_enemy.entity.y)
				var label: String = "→ (%d,%d)" % [tx, ty]
				_entries.append(_make_entry(base_enemy, action_type, label, INTENT_BG_MOVE, 1))
			_:
				_entries.append(_make_entry(base_enemy, action_type, "Wait", INTENT_BG_WAIT, 0))


func _make_entry(
	enemy: BaseEnemy, action_type: String, label: String, color: Color, threat: int
) -> Dictionary:
	return {
		"enemy_name": enemy.entity.entity_name if enemy.entity else "Enemy",
		"action_type": action_type,
		"label": label,
		"color": color,
		"threat": threat,
		"hp_pct": float(enemy.entity.hp) / float(enemy.entity.hp_max) if enemy.entity else 1.0,
	}


func _calculate_threat(attacker: BaseEnemy, target: Node2D, action: Dictionary) -> int:
	## Higher threat = shown first. Lethal attacks are highest.
	if not attacker.entity or not target:
		return 1
	var target_ent: Entity = CombatEntity.get_entity(target)
	if target_ent == null:
		return 1

	var cover_tiles: Array[Vector2i] = []
	if _grid_system:
		for tile: TacTileData in _grid_system.all_tiles():
			if tile.has_cover():
				cover_tiles.append(tile.coords)

	var damage: int = CombatFormula.compute_damage_from_entities(
		attacker.entity, target_ent, cover_tiles
	)
	var would_kill: bool = damage >= target_ent.hp
	var is_aoe: bool = action.get("aoe", false)

	if would_kill:
		return 10
	elif is_aoe:
		return 7
	elif damage >= target_ent.hp_max / 2:
		return 5
	else:
		return 3


func _get_target_name(target: Node2D) -> String:
	if target == null:
		return "?"
	var ent: Entity = CombatEntity.get_entity(target)
	if ent != null:
		return ent.entity_name
	return "?"


func _sort_by_threat() -> void:
	_entries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return int(a["threat"]) > int(b["threat"])
	)


func _build_ui() -> void:
	if _entries.is_empty():
		visible = false
		return

	visible = true
	for entry: Dictionary in _entries:
		var card: PanelContainer = PanelContainer.new()
		var card_style: StyleBoxFlat = StyleBoxFlat.new()
		card_style.bg_color = entry["color"] as Color
		card_style.corner_radius_top_left = 4
		card_style.corner_radius_top_right = 4
		card_style.corner_radius_bottom_right = 4
		card_style.corner_radius_bottom_left = 4
		card.add_theme_stylebox_override("panel", card_style)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)

		var name_label: Label = Label.new()
		name_label.text = entry["enemy_name"] as String
		name_label.add_theme_color_override("font_color", TEXT_COLOR)
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_label)

		var action_label: Label = Label.new()
		action_label.text = entry["label"] as String
		action_label.add_theme_color_override("font_color", TEXT_COLOR)
		action_label.add_theme_font_size_override("font_size", 11)
		action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(action_label)

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 4)
		margin.add_child(vbox)
		card.add_child(margin)

		_flow.add_child(card)
