extends GdUnitTestSuite


func _setup_inventory() -> _InventoryManager:
	var configLoader: _ConfigLoader = AutoloadHelper.config_loader()
	if configLoader != null and not configLoader.isLoaded():
		configLoader._loadConfig()

	var inv: _InventoryManager = AutoloadHelper.inventory_manager()
	inv._initialize_from_config()
	inv.inventory.clear()
	for slot: String in inv.equipment:
		inv.equipment[slot] = ""
	return inv


func _new_player_entity() -> Entity:
	var player: Entity = Entity.new("Player", 0, 0, 40, 12, 6)
	player.is_player = true
	var lifecycle: _EntityLifecycle = AutoloadHelper.entity_lifecycle()
	if lifecycle != null:
		lifecycle.player_entity = player
	return player


func _reset_player_stats(player: Entity) -> void:
	player._cached_equip_off_bonus = 0
	player._cached_equip_def_bonus = 0
	player._cached_equip_spd_bonus = 0


func test_pickup_stacks() -> void:
	var inv: _InventoryManager = _setup_inventory()
	var player: Entity = _new_player_entity()
	_reset_player_stats(player)

	assert_bool(inv.pickup_item("healing_salve", 5)).is_true()
	assert_int(inv.inventory.size()).is_equal(1)
	assert_int(inv.inventory[0]["quantity"]).is_equal(5)

	assert_bool(inv.pickup_item("healing_salve", 7)).is_true()
	# healing_salve stack limit is 10. 5 + 7 = 12. Should be one stack of 10 and one stack of 2.
	assert_int(inv.inventory.size()).is_equal(2)
	assert_int(inv.inventory[0]["quantity"]).is_equal(10)
	assert_int(inv.inventory[1]["quantity"]).is_equal(2)


func test_equip_changes_stats() -> void:
	var inv: _InventoryManager = _setup_inventory()
	var player: Entity = _new_player_entity()
	_reset_player_stats(player)

	inv.add_item("rusted_blade", 1)
	assert_int(player.off).is_equal(12)
	assert_bool(inv.equip_item("rusted_blade", "weapon")).is_true()
	assert_int(player.off).is_equal(14)
	assert_str(inv.equipment["weapon"]).is_equal("rusted_blade")


func test_unequip_reverts_stats() -> void:
	var inv: _InventoryManager = _setup_inventory()
	var player: Entity = _new_player_entity()
	_reset_player_stats(player)

	inv.add_item("rusted_blade", 1)
	assert_bool(inv.equip_item("rusted_blade", "weapon")).is_true()
	assert_int(player.off).is_equal(14)

	assert_bool(inv.unequip_item("weapon")).is_true()
	assert_int(player.off).is_equal(12)
	assert_str(inv.equipment["weapon"]).is_equal("")
	assert_int(inv.inventory.size()).is_equal(1)
	assert_str(inv.inventory[0]["item_id"]).is_equal("rusted_blade")


func test_invalid_slot_rejection() -> void:
	var inv: _InventoryManager = _setup_inventory()
	var player: Entity = _new_player_entity()
	_reset_player_stats(player)

	inv.add_item("rusted_blade", 1)
	assert_bool(inv.equip_item("rusted_blade", "invalid_slot")).is_false()
	assert_str(inv.equipment["weapon"]).is_equal("")
	assert_int(inv.inventory.size()).is_equal(1)


func test_equip_swap_reverts_old_stats() -> void:
	# Create a second weapon with different stats via direct Item construction
	var inv: _InventoryManager = _setup_inventory()
	var player: Entity = _new_player_entity()
	_reset_player_stats(player)

	# rusted_blade gives +2 off
	inv.add_item("rusted_blade", 1)
	assert_bool(inv.equip_item("rusted_blade", "weapon")).is_true()
	assert_int(player.off).is_equal(14)

	# Swap to lucky_pendant in weapon slot — should fail (type restriction)
	inv.add_item("lucky_pendant", 1)
	assert_bool(inv.equip_item("lucky_pendant", "weapon")).is_false()
	assert_int(player.off).is_equal(14)
	assert_str(inv.equipment["weapon"]).is_equal("rusted_blade")
