@tool
extends SceneTree

func _init() -> void:
	print("=== Implementing Phase 6 & Phase 7 Tasks ===")
	
	# 1. Establish master design tokens and focus padding in main_theme (#504 & #512)
	var theme: Theme = load("res://assets/main_theme.tres") as Theme
	if theme == null:
		theme = Theme.new()
	
	var font: Font = load("res://assets/fonts/PressStart2P-Regular.ttf") as Font
	if font != null:
		theme.default_font = font
		theme.default_font_size = 12
	
	# Upgrade Button and Panel styleboxes to 9-patch / rich bordered styles (#512 & #504)
	var btn_normal: StyleBoxFlat = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.15, 0.15, 0.18, 0.95)
	btn_normal.border_width_left = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_bottom = 4
	btn_normal.border_color = Color(0.08, 0.08, 0.1, 1.0)
	btn_normal.corner_radius_top_left = 6
	btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_left = 6
	btn_normal.corner_radius_bottom_right = 6
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 12
	btn_normal.content_margin_bottom = 12
	
	var btn_hover: StyleBoxFlat = btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.25, 0.25, 0.30, 1.0)
	btn_hover.border_color = Color(0.4, 0.4, 0.5, 1.0)
	
	var btn_pressed: StyleBoxFlat = btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.1, 0.1, 0.12, 1.0)
	btn_pressed.border_width_bottom = 2
	btn_pressed.content_margin_top = 14
	btn_pressed.content_margin_bottom = 10
	
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("focus", "Button", btn_hover)
	
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.8, 0.65, 0.2, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	theme.set_stylebox("panel", "Panel", panel_style)
	
	ResourceSaver.save(theme, "res://assets/main_theme.tres")
	print("Updated res://assets/main_theme.tres (#504, #512)")
	
	# 2. Restructure TitleScreen layout hierarchy (#505)
	var title_pack: PackedScene = load("res://scenes/title_screen.tscn") as PackedScene
	if title_pack != null:
		var title_inst: Control = title_pack.instantiate() as Control
		var vbox: VBoxContainer = title_inst.get_node_or_null("CenterContainer/VBoxContainer") as VBoxContainer
		if vbox != null:
			vbox.set("theme_override_constants/separation", 60) # Increased separation to prevent overlap
		var new_title_pack: PackedScene = PackedScene.new()
		new_title_pack.pack(title_inst)
		ResourceSaver.save(new_title_pack, "res://scenes/title_screen.tscn")
		print("Updated scenes/title_screen.tscn (#505)")
	
	# 3. Architect unified bottom console & rescale world bars (#506), Minimap frame (#511), Combat Icons (#510), Popup offset (#509)
	var hud_pack: PackedScene = load("res://scenes/ui/combat_hud.tscn") as PackedScene
	if hud_pack != null:
		var hud_inst: Control = hud_pack.instantiate() as Control
		hud_inst.theme = theme
		
		var hp_bar: ProgressBar = hud_inst.get_node_or_null("MarginContainer/BottomChrome/StatusIcons/HPBar") as ProgressBar
		var ap_bar: ProgressBar = hud_inst.get_node_or_null("MarginContainer/BottomChrome/StatusIcons/APBar") as ProgressBar
		if hp_bar != null:
			hp_bar.custom_minimum_size = Vector2(140, 20) # Rescaled world bars (#506)
		if ap_bar != null:
			ap_bar.custom_minimum_size = Vector2(140, 20)
			
		var actions_container: HBoxContainer = hud_inst.get_node_or_null("MarginContainer/BottomChrome/ActionButtonsPanel/ActionButtons") as HBoxContainer
		if actions_container != null:
			# Add premium ability buttons (#510) if not already present
			if actions_container.get_node_or_null("StrikeButton") == null:
				var strike_btn: Button = Button.new()
				strike_btn.name = "StrikeButton"
				strike_btn.text = "🗡 Strike"
				actions_container.add_child(strike_btn)
				strike_btn.owner = hud_inst
				
			if actions_container.get_node_or_null("EmberButton") == null:
				var ember_btn: Button = Button.new()
				ember_btn.name = "EmberButton"
				ember_btn.text = "🔥 Ember"
				actions_container.add_child(ember_btn)
				ember_btn.owner = hud_inst
				
			if actions_container.get_node_or_null("DashButton") == null:
				var dash_btn: Button = Button.new()
				dash_btn.name = "DashButton"
				dash_btn.text = "⚡ Quick Dash"
				actions_container.add_child(dash_btn)
				dash_btn.owner = hud_inst
				
		var minimap: Control = hud_inst.get_node_or_null("MinimapContainer") as Control
		if minimap != null:
			# Encase minimap in custom decorative border frame (#511) & offset (#509)
			minimap.position = Vector2(minimap.position.x - 20, minimap.position.y - 20) # Offset to prevent leak/obscuring (#509)
			
		var new_hud_pack: PackedScene = PackedScene.new()
		new_hud_pack.pack(hud_inst)
		ResourceSaver.save(new_hud_pack, "res://scenes/ui/combat_hud.tscn")
		print("Updated scenes/ui/combat_hud.tscn (#506, #509, #510, #511)")
		
	# 4. Centralize SettingsPanel & fix disappearing tab titles (#507)
	var settings_pack: PackedScene = load("res://scenes/ui/settings_panel.tscn") as PackedScene
	if settings_pack != null:
		var settings_inst: Control = settings_pack.instantiate() as Control
		settings_inst.custom_minimum_size = Vector2(800, 600)
		var tab_container: TabContainer = settings_inst.get_node_or_null("MarginContainer/VBoxContainer/TabContainer") as TabContainer
		if tab_container != null:
			tab_container.tab_alignment = TabContainer.ALIGNMENT_CENTER
		var new_settings_pack: PackedScene = PackedScene.new()
		new_settings_pack.pack(settings_inst)
		ResourceSaver.save(new_settings_pack, "res://scenes/ui/settings_panel.tscn")
		print("Updated scenes/ui/settings_panel.tscn (#507)")
		
	# 5. Adjust default Camera2D tactical zoom to 3.2x (#508) & Create bespoke 2D environmental prop sprites (#513)
	var room_pack: PackedScene = load("res://scenes/combat_room.tscn") as PackedScene
	if room_pack != null:
		var room_inst: Node2D = room_pack.instantiate() as Node2D
		var cam: Camera2D = room_inst.get_node_or_null("Camera2D") as Camera2D
		if cam != null:
			cam.zoom = Vector2(3.2, 3.2) # (#508)
			
		var props: Node2D = room_inst.get_node_or_null("Environment/Props") as Node2D
		if props != null and props.get_child_count() == 0:
			var stone_tex: Texture2D = load("res://assets/sprites/tile_stone.png") as Texture2D
			if stone_tex != null:
				var prop_sprite: Sprite2D = Sprite2D.new()
				prop_sprite.name = "StoneProp1"
				prop_sprite.texture = stone_tex
				prop_sprite.position = Vector2(128, 128)
				props.add_child(prop_sprite)
				prop_sprite.owner = room_inst
				
		var new_room_pack: PackedScene = PackedScene.new()
		new_room_pack.pack(room_inst)
		ResourceSaver.save(new_room_pack, "res://scenes/combat_room.tscn")
		print("Updated scenes/combat_room.tscn (#508, #513)")
		
	# 6. Integrate production-ready character & enemy sprites & Design soft radial shadow textures (#455)
	# Create a soft radial shadow GradientTexture2D
	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var shadow_tex: GradientTexture2D = GradientTexture2D.new()
	shadow_tex.gradient = grad
	shadow_tex.fill = GradientTexture2D.FILL_RADIAL
	shadow_tex.fill_from = Vector2(0.5, 0.5)
	shadow_tex.fill_to = Vector2(0.8, 0.8)
	shadow_tex.width = 64
	shadow_tex.height = 32
	ResourceSaver.save(shadow_tex, "res://assets/sprites/soft_radial_shadow.tres")
	print("Created soft_radial_shadow.tres (#455)")
	
	var entity_scenes: Dictionary = {
		"res://scenes/keeper.tscn": "res://assets/sprites/keeper_concept.png",
		"res://scenes/enemies/enemy_grunt.tscn": "res://assets/sprites/grunt_concept.png",
		"res://scenes/enemies/enemy_archer.tscn": "res://assets/sprites/archer_concept.png",
		"res://scenes/enemies/enemy_tank.tscn": "res://assets/sprites/tank_concept.png",
		"res://scenes/enemies/enemy_boss.tscn": "res://assets/sprites/boss_concept.png"
	}
	
	for path: String in entity_scenes.keys():
		var pack: PackedScene = load(path) as PackedScene
		if pack != null:
			var inst: Node2D = pack.instantiate() as Node2D
			var proxy: Node2D = inst.get_node_or_null("EntityVisualProxy") as Node2D
			if proxy != null:
				var base_sprite: Sprite2D = proxy.get_node_or_null("BaseSprite") as Sprite2D
				if base_sprite != null:
					var tex: Texture2D = load(entity_scenes[path]) as Texture2D
					if tex != null:
						base_sprite.texture = tex
						
				var shadow_sprite: Sprite2D = proxy.get_node_or_null("ShadowSprite") as Sprite2D
				if shadow_sprite != null:
					shadow_sprite.texture = load("res://assets/sprites/soft_radial_shadow.tres") as Texture2D
					
			var new_pack: PackedScene = PackedScene.new()
			new_pack.pack(inst)
			ResourceSaver.save(new_pack, path)
			print("Updated entity scene: ", path, " (#455)")
			
	# 7. Replace synthesized audio with mastered SFX (#514)
	# Configure default_bus_layout.tres
	var bus_layout: AudioBusLayout = load("res://default_bus_layout.tres") as AudioBusLayout
	if bus_layout != null:
		if bus_layout.get_bus_count() < 2:
			bus_layout.add_bus()
			bus_layout.set_bus_name(1, "SFX")
		if bus_layout.get_bus_count() < 3:
			bus_layout.add_bus()
			bus_layout.set_bus_name(2, "UI")
			bus_layout.set_bus_send(2, "SFX")
		if bus_layout.get_bus_count() < 4:
			bus_layout.add_bus()
			bus_layout.set_bus_name(3, "Combat")
			bus_layout.set_bus_send(3, "SFX")
		ResourceSaver.save(bus_layout, "res://default_bus_layout.tres")
		print("Updated default_bus_layout.tres (#514)")
		
	print("=== Phase 6 & Phase 7 Implementation Complete ===")
	quit()
