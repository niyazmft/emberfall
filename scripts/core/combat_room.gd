class_name CombatRoom
extends Node2D
## The root scene for all tactical gameplay.
## Handles the core visual architecture defined in AGENTS.md:
##   - GridRenderer: Isometric floor
##   - EntityContainer (YSort): Depth-sorted game entities
##   - UIOverlay: CanvasLayer for HUD and menus

@onready var grid_renderer: Node2D = $GridRenderer
@onready var entity_container: Node2D = $EntityContainer
@onready var ui_overlay: CanvasLayer = $UIOverlay


func _ready() -> void:
	pass
