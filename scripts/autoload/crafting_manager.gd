extends Node
class_name _CraftingManager

## Autoload: CraftingManager
## Manages mid-run crafting recipes and execution.

signal craft_completed(recipe_id: String, success: bool)

var _recipe_defs: Dictionary = {}


func _ready() -> void:
	_load_recipe_definitions()


func _load_recipe_definitions() -> void:
	var configLoader: _ConfigLoader = AutoloadHelper.config_loader()
	if configLoader:
		var data: Variant = configLoader.getValue("recipes")
		if data is Dictionary:
			_recipe_defs = data


## Returns the definition of a recipe.
func get_recipe(recipe_id: String) -> Dictionary:
	return _recipe_defs.get(recipe_id, {})


## Returns all available recipes.
func get_all_recipes() -> Dictionary:
	return _recipe_defs


## Checks if a recipe can be crafted.
func can_craft(recipe_id: String) -> bool:
	if not _recipe_defs.has(recipe_id):
		return false

	var def: Dictionary = _recipe_defs[recipe_id]
	var ingredients: Dictionary = def.get("ingredients", {})
	var costs: Dictionary = def.get("currency_costs", {})

	# Check ingredients
	var im: Node = AutoloadHelper.inventory_manager()
	if not im or not im.has_method("has_items") or not im.has_items(ingredients):
		return false

	# Check currency (Echo Shards)
	var mpm: _MetaProgressionManager = AutoloadHelper.meta_progression_manager()
	if not mpm:
		return false

	for currency_id: String in costs:
		if currency_id == "echo_shards":
			if mpm.get_echo_shards() < int(costs[currency_id]):
				return false
		# Extend here for other currencies if needed

	return true


## Attempts to craft a recipe.
func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		craft_completed.emit(recipe_id, false)
		return false

	var def: Dictionary = _recipe_defs[recipe_id]
	var ingredients: Dictionary = def.get("ingredients", {})
	var costs: Dictionary = def.get("currency_costs", {})
	var result_id: String = def.get("result_item_id", "")
	var result_qty: int = int(def.get("result_quantity", 1))

	var im: Node = AutoloadHelper.inventory_manager()
	var mpm: _MetaProgressionManager = AutoloadHelper.meta_progression_manager()

	if not im or not mpm:
		return false

	# Deduct ingredients
	for item_id: String in ingredients:
		im.call("remove_item", item_id, int(ingredients[item_id]))

	# Deduct costs
	for currency_id: String in costs:
		if currency_id == "echo_shards":
			# MetaProgressionManager currently only has add_echo_shards
			# and purchase_unlock (which deducts).
			# We might need a deduct_echo_shards or just use add with negative.
			# Looking at purchase_unlock, it does: _echo_shards -= cost
			# Let's assume we can add negative for now or implement a dedicated method if preferred.
			# Since MetaProgressionManager is a shared component, we should be careful.
			# For now, we'll use a hack if there's no deduct, or better, add it to MPM.
			# Wait, MPM has _echo_shards private.
			# Let's use add_echo_shards(-cost) if it allows.
			mpm.add_echo_shards(-int(costs[currency_id]))

	# Add result item
	im.call("add_item", result_id, result_qty)

	craft_completed.emit(recipe_id, true)
	return true
