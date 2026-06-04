extends SceneTree

func _init() -> void:
	print("Validating CombatInput syntax and loading...")

	var player: Node2D = Node2D.new()
	var enemies: Node2D = Node2D.new()
	var grid_renderer: Node2D = Node2D.new()

	var script: GDScript = load("res://scripts/core/combat_input.gd") as GDScript
	if not script:
		print("FAILED: Could not load combat_input.gd")
		quit(1)
		return

	var ci: Node = script.new(player, enemies, grid_renderer) as Node
	if ci:
		print("SUCCESS: CombatInput instantiated")
		if ci.has_method("handle_input"):
			print("SUCCESS: handle_input method found")
		else:
			print("FAILED: handle_input method NOT found")
	else:
		print("FAILED: CombatInput instantiation failed")

	ci.free()
	grid_renderer.free()
	enemies.free()
	player.free()
	quit(0)
