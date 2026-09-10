extends MarginContainer


onready var row_proto = load("res://mods-unpacked/meinfesl-AdvancedStatistics/ui/stats_row.tscn").instance()
onready var tracker = get_tree().get_root().get_node("ModLoader/meinfesl-AdvancedStatistics/StatsTracker")
onready var stats = get_tree().get_root().get_node("ModLoader/meinfesl-AdvancedStatistics/StatsTracker").run_stats
onready var other_color = Utils.SECONDARY_FONT_COLOR

var player_index = 0
var inventory_popup
var standalone_popup
var weapons_container
var items_container
var last_row

func build_statistics():
	last_row = null
	# Can't do it right away, inventory is not loaded yet
	call_deferred("build_statistic_impl")


func build_statistic_impl():
	tracker = RunData.advstats_for(player_index)
	stats = tracker.run_stats
	var vbox = $ScrollContainer/MarginContainer/VBoxContainer
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()
	
	RunData.tracked_item_effects[player_index][Keys.item_scared_sausage_hash] = RunData.advstats_for(player_index).run_stats["DAMAGE_SAUSAGE"]
	
	build_damage_stats()
	build_survivability_stats()
	build_enemies_stats()
	build_econ_stats()


func make_time(time_in_ms):
	var seconds:float = fmod(time_in_ms, 60 * 1000) / 1000
	var minutes:int   =  int(time_in_ms / (60 * 1000))
	return "%02d:%05.2f" % [minutes, seconds]


func get_damage_source(dmg_source):
	if dmg_source == "":
		return null
	
	for item in ItemService.items:
		if item.my_id == dmg_source:
			return item
	
	for weapon in ItemService.weapons:
		if weapon.my_id == dmg_source:
			return weapon
	
	for character in ItemService.characters:
		if character.my_id == dmg_source:
			return character
	
	return null


func build_damage_stats():
	add_row("Run Time:", make_time(stats["RUN_TIME"]), other_color)
	
	if RunData.current_wave == RunData.nb_of_waves:
		add_row("Wave 20:", make_time(tracker.wave_stats["TIME"]), other_color)
	
	add_row("", "")
	
	add_row("Damage:", "", other_color)

	var damage_done_full = stats["DAMAGE_DONE_OVERKILL"]
	var damage_done = stats["DAMAGE_DONE"]
	var damage_done_pct = calc_pct(damage_done, damage_done_full)
	var overkill = damage_done_full - damage_done
	var overkill_pct = calc_pct(overkill, damage_done_full)
	var weapon_damage = stats["DAMAGE_DONE_WEAPONS"]

	add_row("   Full Damage Done","%d" % [damage_done_full])
	add_row("      Effective Damage", "%d (%6.2f%%)" % [damage_done, damage_done_pct], other_color)
	add_row("      Overkill Damage", "%d (%6.2f%%)" % [overkill, overkill_pct], other_color)
	add_row("   Highest Hit", "%d" % stats["MAX_DAMAGE"])
	var damage_source = get_damage_source(stats["MAX_DAMAGE_SOURCE"])
	if damage_source:
		last_row.init_popup(null, standalone_popup, damage_source)
	
	add_row("   Damage Done", "%d" % damage_done)
	
	var character_passive = 0
	var char_name = RunData.get_player_character(player_index).my_id
	if tracker.tracked_items.get(char_name, "") == "DAMAGE_DONE":
		character_passive = RunData.tracked_item_effects[player_index].get(Keys.generate_hash(char_name), 0)
		if character_passive:
			var character = null
			for it in items_container.get_children():
				if it.item.my_id == char_name:
					character = it
					break
			add_row("      Character Passive:", make_pct(character_passive, damage_done), other_color, character)
	
	add_row("      Weapons", make_pct(weapon_damage, damage_done), other_color)
	
	var previous_weapons = weapon_damage
	
	var weapons = RunData.get_player_weapons_ref(player_index)
	for i in weapons.size():
		var weapon = weapons[i]
		var damage = stats["DAMAGE_BY_WEAPON"][i]
		var tier_number = ItemService.get_tier_number(weapon.tier)
		var weapon_name = tr(weapon.name) + (" " + tier_number if tier_number != "" else "")
		add_row_weapon("         %s" % weapon_name, make_pct(damage, damage_done), i)
		var burn = stats["DAMAGE_BY_WEAPON_BURN"][i]
		if burn:
			var direct = damage - burn
			add_row_weapon("            Direct", make_pct(direct, damage_done), i, other_color)
			add_row_weapon("            Burn", make_pct(burn, damage_done), i, other_color)
		previous_weapons -= damage
	
	if previous_weapons:
		add_row("         Previous Weapons", make_pct(previous_weapons, damage_done))
	
	var tracked_items = { }
	var tracked_structures = { }
	
	for i in tracker.tracked_items:
		if  tracker.tracked_items[i] == "DAMAGE_DONE":
			if i.find("turret") != -1:
				tracked_structures[i] = 0
				continue
			if i.find("character") != - 1:
				continue
			match i:
				"item_giant_belt":
					pass
				"item_greek_fire":
					pass
				"item_landmines":
					tracked_structures[i] = 0
				"item_tyler":
					tracked_structures[i] = 0
				"item_pocket_factory":
					tracked_structures[i] = 0
				_:
					tracked_items[i] = 0
	
	var items = 0
	for key in tracked_items:
		var dmg = RunData.tracked_item_effects[player_index].get(Keys.generate_hash(key), 0)
		if dmg is Array:
			tracked_items[key] += dmg[0]
			items += dmg[0]
			if key == "item_bonk_dog":
				tracked_items[key] += dmg[1]
				items += dmg[1]
		else:
			tracked_items[key] = dmg
			items += dmg
	
	var lootworm = stats["DAMAGE_LOOTWORM"]
	if lootworm > 0:
		items += lootworm
		tracked_items["item_lootworm"] = lootworm
	
	if items:
		add_row("      Items", make_pct(items, damage_done), other_color)
		for key in tracked_items:
			var dmg = tracked_items[key]
			if dmg:
				add_row_item(3, key, dmg, damage_done)
	
	var structures = 0
	for key in tracked_structures:
		# Builder turret
		if key == "item_turret_flame":
			if RunData.get_player_character(player_index).my_id == "character_builder" and RunData.get_player_item(Keys.item_turret_flame_hash, player_index) == null:
				continue
		var dmg = RunData.tracked_item_effects[player_index].get(Keys.generate_hash(key), 0)
		if dmg is Array:
			for d in dmg:
				tracked_structures[key] += d
				structures += d
		else:
			tracked_structures[key] = dmg
			structures += dmg
	
	var builder_turret = null
	var builder_turret_damage = stats["DAMAGE_BUILDER_TURRET"]
	for turret_hash in Keys.item_builder_turret_n_hash:
		builder_turret = RunData.get_player_item(turret_hash, player_index)
		if builder_turret:
			break
	
	
	if builder_turret_damage and RunData.get_player_item(Keys.item_turret_flame_hash, player_index) == null:
		builder_turret_damage += RunData.tracked_item_effects[player_index][Keys.item_turret_flame_hash]
	structures += builder_turret_damage
	
	if structures:
		add_row("      Structures", make_pct(structures, damage_done), other_color)
		# Builder turret
		for key in tracked_structures:
			if RunData.get_player_character(player_index).my_id == "character_builder" and key == "item_turret_flame":
				if RunData.get_player_item(Keys.item_turret_flame_hash, player_index) == null:
					continue
			
			var dmg = tracked_structures[key]
			if dmg:
				add_row("         %s" % tr(key.to_upper()), make_pct(dmg, damage_done))
				var dmg_source = get_damage_source(key)
				if dmg_source:
					last_row.init_popup(null, standalone_popup, dmg_source)
		
		if builder_turret_damage:
			add_row("         %s" % tr("ITEM_BUILDER_TURRET"), make_pct(builder_turret_damage, damage_done))
			for element in items_container.get_children():
				if element.item == builder_turret:
					last_row.init_popup(inventory_popup, null, element)
					break
	
	var other_damage = damage_done - character_passive - weapon_damage - items - structures
	
	if other_damage:
		add_row("      Other Sources", make_pct(other_damage, damage_done), other_color)


func build_enemies_stats():
	add_row("", "")
	add_row("Enemies:", "", other_color)
	add_row("   Enemies Killed", "%d" % stats["KILLS_ENEMIES"])
	add_row("   Elites Killed", "%d" % stats["KILLS_ELITES"])
	add_row("   Trees Killed", "%d" % stats["KILLS_TREES"])
	
	var loot_aliens_spawned = stats["SPAWNED_LOOT_ALIENS"]
	var loot_aliens_killed = stats["KILLS_LOOT_ALIENS"]
	
	add_row("   Loot Aliens Spawned", "%d" % loot_aliens_spawned)
	add_row("      Loot Aliens Killed", make_pct(loot_aliens_killed, loot_aliens_spawned), other_color)


func build_survivability_stats():
	add_row("", "")
	add_row("Survivability:", "", other_color)
	
	var damage_taken = stats["DAMAGE_TAKEN"]
	var damage_taken_self = stats["DAMAGE_TAKEN_SELF"]
	
	add_row("   Damage Taken", "%d" % stats["DAMAGE_TAKEN"])
	if damage_taken_self:
		add_row("      From Enemies", make_pct(damage_taken - damage_taken_self, damage_taken), other_color)
		add_row("      Self-inflicted", make_pct(damage_taken_self, damage_taken), other_color)
	
	add_row("   Damage Reduced By Armor", "%d" % stats["DAMAGE_TAKEN_ARMOR"])
	if stats["DAMAGE_TAKEN_ARMOR_NEGATIVE"]:
		add_row("   Damage Increased By Armor", "%d" % stats["DAMAGE_TAKEN_ARMOR_NEGATIVE"])
	add_row("   Hits Taken", "%d" % stats["HITS_TAKEN"])
	add_row("   Hits Dodged", "%d" % stats["HITS_DODGED"])
	
	var tracked_items = { }
	
	for i in tracker.tracked_items:
		if tracker.tracked_items[i] == "HP_HEALED":
			tracked_items[i] = 0
	
	var heal_total = stats["HP_HEALED"]
	var fruit = stats["HP_HEALED_FRUIT"]
	var lifesteal = stats["HP_HEALED_LIFESTEAL"]
	var regen = stats["HP_HEALED_REGEN"]
		
	var items = 0
	for key in tracked_items:
		var heal = RunData.tracked_item_effects[player_index].get(Keys.generate_hash(key), 0)
		if heal is Array:
			tracked_items[key] += heal[0]
			items += heal[0]
		else:
			tracked_items[key] = heal
			items += heal
	
	var doc_moth = tracked_items.get("item_doc_moth", 0)
	items -= doc_moth
	
	var other = heal_total - fruit - lifesteal - regen - items
	
	add_row("   HP Healed", "%d" % heal_total)
	if heal_total:
		add_row("      Fruit", make_pct(fruit, heal_total), other_color)
		add_row("      Lifesteal", make_pct(lifesteal, heal_total), other_color)
		var doc_moth_ls = stats.get("DOC_MOTH_LIFESTEAL", 0)
		if doc_moth_ls > 0:
			add_row_item(3, "item_doc_moth", doc_moth_ls, heal_total)
		add_row("      HP Regeneration", make_pct(regen, heal_total), other_color)
		var doc_moth_regen = stats.get("DOC_MOTH_REGEN", 0)
		if doc_moth_regen > 0:
			add_row_item(3, "item_doc_moth", doc_moth_regen, heal_total)
	
	if items:
		for key in tracked_items:
			var heal = tracked_items[key]
			if heal:
				add_row_item(2, key, heal, heal_total, other_color)
	
	if other:
		add_row("      Other Sources", make_pct(other, heal_total), other_color)


func build_econ_stats():
	add_row("", "")
	add_row("Economy:", "", other_color)
	
	var tracked_items = { }
	
	for i in tracker.tracked_items:
		if tracker.tracked_items[i] == "MATERIALS_GAINED":
			if i == "item_metal_detector" or i == "item_recycling_machine":
				continue
			tracked_items[i] = 0
	
	var mat_all = stats["MATERIALS_GAINED"]
	var mat_picked_up = stats["MATERIALS_GAINED_PICKED_UP"]
	var mat_metal_detector = RunData.tracked_item_effects[player_index].get("item_metal_detector", 0)
	var mat_harvesting = stats["MATERIALS_GAINED_HARVESTING"]
	var mat_recycling = stats["MATERIALS_GAINED_RECYCLING"]
	var mat_recycling_machine = RunData.tracked_item_effects[player_index].get("item_recycling_machine", 0)
	var mat_crit = stats["MATERIALS_GAINED_WEAPON_CRIT"]

	# it's already included in picked up
	var lootworm = RunData.tracked_item_effects[player_index].get(Keys.generate_hash("item_lootworm"), 0)
	mat_picked_up -= lootworm
	
	var items = 0
	for key in tracked_items:
		var materials = RunData.tracked_item_effects[player_index].get(Keys.generate_hash(key), 0)
		if materials is Array:
			for m in materials:
				tracked_items[key] += m
				items += m
		tracked_items[key] = materials
		items += materials
	
	var mat_other = mat_all - mat_picked_up - mat_harvesting - mat_recycling - mat_crit - items

	add_row("   Materials Gained", "%d" % mat_all)
	add_row("      Picked Up", make_pct(mat_picked_up, mat_all), other_color)
	if mat_metal_detector:
		add_row_item(3, "item_metal_detector", mat_metal_detector, mat_all)
	add_row("      Harvesting", make_pct(mat_harvesting, mat_all), other_color)
	add_row("      Recycling", make_pct(mat_recycling, mat_all), other_color)
	if mat_recycling_machine:
		add_row_item(3, "item_recycling_machine", mat_recycling_machine, mat_all)
	if mat_crit:
		add_row("      Critical Kills", make_pct(mat_crit, mat_all), other_color)
	
	for key in tracked_items:
		var value = tracked_items[key]
		if value:
			add_row_item(2, key, value, mat_all, other_color)
	
	if mat_other:
		add_row("      Other Sources", make_pct(mat_other, mat_all), other_color)
	
	var spent_all = stats["MATERIALS_SPENT"]
	var spent_shop = stats["MATERIALS_SPENT_SHOP"]
	var spent_reroll_shop = stats["MATERIALS_SPENT_REROLL_SHOP"]
	var spent_reroll_level_up = stats["MATERIALS_SPENT_REROLL_LEVEL_UP"]
	var spent_other = spent_all - spent_shop - spent_reroll_shop - spent_reroll_level_up
	
	add_row("   Materials Spent", "%d" % spent_all)
	add_row("      Shop Items", make_pct(spent_shop, spent_all), other_color)
	add_row("      Shop Rerolls", make_pct(spent_reroll_shop, spent_all), other_color)
	add_row("      Level-up Rerolls", make_pct(spent_reroll_level_up, spent_all), other_color)
	if spent_other:
		add_row("      Other Sources", make_pct(spent_other, spent_all), other_color)
	
	if RunData.get_player_character(player_index).my_id == "character_builder":
		add_row("   Materials consumed by Builder's turret", "%d" % stats["MATERIALS_CONVERTED"])
	
	add_row("   Shop Items Browsed", "%d" % stats["SHOP_ITEMS_BROWSED"])
	add_row("      Shop Items Bought", make_pct(stats["SHOP_ITEMS_BOUGHT"], stats["SHOP_ITEMS_BROWSED"]), other_color)
	
	var boxes_taken = stats["LOOT_BOXES_TAKEN"]
	var boxes_discarded = stats["LOOT_BOXES_DISCARDED"]
	
	add_row("   Loot Boxes", "%d" % (boxes_taken + boxes_discarded))
	add_row("      Taken", make_pct(boxes_taken, boxes_taken + boxes_discarded), other_color)
	add_row("      Recycled", make_pct(boxes_discarded, boxes_taken + boxes_discarded), other_color)


func add_row_weapon(name:String, value:String, index, color = null):
	var element = weapons_container.get_children()[index]
	add_row(name, value, color, element)


func add_row_item(padding:int, id:String, value:int, total:int, color = null):
	var item = null
	for it in items_container.get_children():
		if it.item.my_id == id:
			item = it
			break
	var name = make_item_name(padding, id)
	var value_str = make_pct(value, total)
	add_row(name, value_str, color, item)


func add_row(name:String, value:String, color = null, element = null):
	var row = row_proto.duplicate()
	row.player_index = player_index
	var hbox = row.get_node("MarginContainer/HBoxContainer")
	hbox.get_node("Name").text = name
	hbox.get_node("Value").text = value
	
	if name == "":
		hbox.focus_mode = FOCUS_NONE
		row.get_node("Back").hide()
	
	if color:
		hbox.get_node("Name").set("custom_colors/font_color", color)
		hbox.get_node("Value").set("custom_colors/font_color", color)
	
	if element:
		row.init_popup(inventory_popup, null, element)
	
	$ScrollContainer/MarginContainer/VBoxContainer.add_child(row)
	
	last_row = row


func make_item_name(padding:int, id:String)->String:
	var string = ""
	for i in padding:
		string += "   "
	string += tr(id.to_upper())
	var nb = RunData.get_nb_item(Keys.generate_hash(id), player_index)
	if nb > 1:
		string += " (x%d)" % nb
	return string


func make_pct(val, total):
	return "%d (%6.2f%%)" % [val, calc_pct(val, total)]


func calc_pct(val, base)->float:
	var pct:float = 0.0
	if base != 0:
		pct = val * 100.0 / base
	return pct


