extends Node

## BurdenVisuals
## Handles visual/logical effects for Burden Events.
## Implementation of DON-223.

func _ready() -> void:
	if BurdenManager:
		BurdenManager.burden_event_triggered.connect(on_entity_burden_triggered)

func on_entity_burden_triggered(_result: RefCounted) -> void:
	# Wire router reset or other logic here if needed.
	# For DON-223, this is a requested hook.
	if AudioMiddleware and AudioMiddleware.has_method("get_stem_router"):
		var router: Node = AudioMiddleware.get_stem_router()
		if router:
			router.reset_cooldowns()

	_print_debug("OnEntityBurdenTriggered fired")

func _print_debug(msg: String) -> void:
	if OS.is_debug_build():
		print("BurdenVisuals: %s" % msg)
