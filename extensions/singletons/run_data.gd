extends "res://singletons/run_data.gd"

var mod_advstats


func reset(restart:bool = false)->void:
	# Do it before base reset because of adding starting weapons
	mod_advstats = get_tree().get_root().get_node("ModLoader/meinfesl-AdvancedStatistics/StatsTracker")
	for tracker in advstats_all(): tracker.reset()
	
	.reset(restart)


func add_weapon_dmg_dealt(pos: int, dmg_dealt: int, player_index: int)->void:
	.add_weapon_dmg_dealt(pos, dmg_dealt, player_index)
	advstats_for(player_index).on_weapon_damage(pos, dmg_dealt)


func add_gold(value:int, player_index: int)->void:
	.add_gold(value, player_index)
	advstats_for(player_index).on_materials_gained(value)


func remove_gold(value:int, player_index: int)->void:
	.remove_gold(value, player_index)
	advstats_for(player_index).on_materials_spent(value)


func remove_currency(value:int, player_index: int)->void:
	advstats_for(player_index).run_stats["SHOP_ITEMS_BOUGHT"] += 1
	advstats_for(player_index).materials_source = "MATERIALS_SPENT_SHOP"
	.remove_currency(value, player_index)
	advstats_for(player_index).materials_source = ""


func resume_from_state(state:Dictionary)->void:
	.resume_from_state(state)
	advstats_restore_all()


func add_weapon(weapon: WeaponData, player_index: int, is_selection: bool = false)->WeaponData:
	var added_weapon = .add_weapon(weapon, player_index, is_selection)
	advstats_for(player_index).on_weapon_added(weapon)
	return added_weapon


func remove_weapon(weapon:WeaponData, player_index: int)->int:
	advstats_for(player_index).on_weapon_removed(weapon)
	return .remove_weapon(weapon, player_index)

func remove_weapon_by_index(index: int, player_index: int) -> int:
	advstats_for(player_index).on_weapon_index_removed(index)
	return .remove_weapon_by_index(index, player_index)


func remove_all_weapons(player_index: int)->void:
	.remove_all_weapons(player_index)
	advstats_for(player_index).remove_all_weapons()

func add_tracked_value(player_index: int, tracking_key: int, value: float, index: int = 0)->void :
	.add_tracked_value(player_index, tracking_key, value, index)

	advstats_for(player_index).add_tracked_value(tracking_key, value)
	

# Why here? because it's in _ready of main.gd
func reset_cache()->void:
	.reset_cache()
	#var val:int = tracked_item_effects[0]["item_piggy_bank"]
	#tracked_item_effects[0]["item_piggy_bank"] = val

func init_tracked_effects() -> Dictionary:
	var base = .init_tracked_effects()
	var ext = {
		Keys.generate_hash("item_pocket_factory"):0,
	}
	base.merge(ext)
	return base

func advstats_for(index: int):
	if index < 0 or index >= 4: return null
	var suffix = "" if index == 0 else str(index)
	return get_node_or_null("/root/ModLoader/meinfesl-AdvancedStatistics/StatsTracker"+suffix)
func advstats_all() -> Array:
	var result = []
	for i in 4:
		var tracker = advstats_for(i)
		if tracker != null: result.append(tracker)
	return result
func advstats_restore_all():
	for tracker in advstats_all(): tracker.resum_from_state()
