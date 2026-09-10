extends Node

class CharacterStats:
	var name
	var characters:Dictionary
	
	
	func update_value(char_id:String, stat:String, value):
		characters[char_id][stat] = value
	
	
	func add_value(char_id:String, stat:String, value):
		var c = characters[char_id]
		if c.has(stat):
			c[stat] += value
		else:
			c[stat] = value
	
	
	func get_value(char_id:String, stat:String, default):
		var c = characters.get(char_id, null)
		if !c:
			return default
		return c.get(stat, default)
	
	
	func save(path:String):
		var d = Directory.new()
		if !d.dir_exists(path):
			d.make_dir_recursive(path)
		
		var file:File = File.new()
		var err = file.open(path + "/" + name, File.WRITE)
		if err != OK:
			return
		file.store_var(characters, true)
		file.close()
	
	
	func load(path:String):
		var file:File = File.new()
		if file.file_exists(path + "/" + name):
			var err = file.open(path + "/" + name, File.READ)
			if err != OK:
				return
			characters = file.get_var(true)
			file.close()


var owner_index = 0
var tracked_items:Dictionary

var wave_stats:Dictionary
var run_stats:Dictionary
var run_stats_saved = null

var mod_state:Dictionary

var template_stats
var character_stats_normal = []
var character_stats_endless = []

var heal_source = ""
var materials_source = ""

var levelup:bool = false

var combining_weapons:bool = false
var combining_weapons_damage:int = 0
var combining_weapons_damage_burn:int = 0

var exploding_weapon = null

var burn:bool = false
var sausage:bool = false
var run_in_progress:bool = false
var wave_in_progress:bool = false
var last_time:int = -1

var waiting_for_damage_source:bool = false
var damage_source:String = ""
var damage_tracking_key:int = Keys.empty_hash

var sturcure_spawn_counter:int = 0

var run_lost:bool = false
var run_won:bool = false


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	for i in ProgressData.MAX_DIFFICULTY + 1:
		var data = CharacterStats.new()
		data.name = "normal_d" + str(i)
		character_stats_normal.push_back(data)
		
		data = CharacterStats.new()
		data.name = "endless_d" + str(i)
		character_stats_endless.push_back(data)
		
	template_stats = init_character_stats()
	var _err = RunData.connect("bonus_gold_converted", self, "on_gold_converted");


func _process(_delta):
	var time_now = Time.get_ticks_msec()
	var diff = time_now - last_time
	last_time = time_now
	
	waiting_for_damage_source = false
	
	if run_in_progress and owner_index < RunData.get_player_count():
		run_stats["RUN_TIME"] += diff
		if wave_in_progress:
			wave_stats["TIME"] += diff


func reset():
	run_in_progress = false
	wave_in_progress = false
	heal_source = ""
	materials_source = ""
	damage_source = ""
	damage_tracking_key = Keys.empty_hash
	combining_weapons = false
	combining_weapons_damage = 0
	combining_weapons_damage_burn = 0
	exploding_weapon = null
	levelup = false
	burn = false
	sausage = false
	waiting_for_damage_source = false
	last_time = -1
	sturcure_spawn_counter = 0
	run_lost = false
	run_won = false
	run_stats = init_run_stats()
	wave_stats = init_wave_stats()


func on_wave_started():
	if owner_index >= RunData.get_player_count(): return
	if last_time == -1:
		last_time = Time.get_ticks_msec()
	run_in_progress = true
	wave_in_progress = true
	wave_stats = init_wave_stats()


func on_game_paused():
	run_in_progress = false


func on_game_unpaused():
	if owner_index >= RunData.get_player_count(): return
	run_in_progress = true


func on_enemy_spawned(enemy):
	if enemy.stats.always_drop_consumables and enemy.stats.can_drop_consumables and enemy.is_loot:
		run_stats["SPAWNED_LOOT_ALIENS"] += 1

func on_structure_spawned(structure):
	sturcure_spawn_counter += 1
	
	var path = structure.get_path()
	var structure_name = path.get_name(path.get_name_count() - 1)
	
	if structure_name.begins_with("@"):
		structure_name = structure_name.substr(1)
			
	if structure_name.begins_with("Turret"):
		if sturcure_spawn_counter > RunData.get_player_effect(Keys.structures_hash, owner_index).size():
			structure.mod_tooltiptracking_key = Keys.item_pocket_factory_hash

func on_enemy_damage_taken(damage:Array, hitbox:Hitbox):
	run_stats["DAMAGE_DONE_OVERKILL"] += damage[0]
	run_stats["DAMAGE_DONE"] += damage[1]
	
	for builder_turret in Keys.item_builder_turret_n_hash:
		if hitbox and hitbox.damage_tracking_key_hash == builder_turret:
			run_stats["DAMAGE_BUILDER_TURRET"] += damage[1]
			break
	
	if hitbox and hitbox.from and is_instance_valid(hitbox.from):
		if hitbox.from is Lootworm:
			run_stats["DAMAGE_LOOTWORM"] += damage[1]
	
	if run_stats["MAX_DAMAGE"] < damage[0]:
		run_stats["MAX_DAMAGE"] = damage[0]
		
		if hitbox:
			if hitbox.from:
				var weapons = RunData.get_player_weapons(owner_index)
				if is_instance_valid(hitbox.from) && "weapon_pos" in hitbox.from && hitbox.from.weapon_pos < weapons.size():
					run_stats["MAX_DAMAGE_SOURCE"] = weapons[hitbox.from.weapon_pos].my_id
				elif hitbox.damage_tracking_key_hash != Keys.empty_hash:
					run_stats["MAX_DAMAGE_SOURCE"] = Keys.hash_to_string[hitbox.damage_tracking_key_hash]
				else:
					waiting_for_damage_source = true
					run_stats["MAX_DAMAGE_SOURCE"] = ""
			# Is this obsolete?
			elif hitbox.damage_tracking_key_hash != Keys.empty_hash:
				run_stats["MAX_DAMAGE_SOURCE"] = Keys.hash_to_string[hitbox.damage_tracking_key_hash]
		elif damage_source != "":
			run_stats["MAX_DAMAGE_SOURCE"] = damage_source
		elif damage_tracking_key != Keys.empty_hash:
			run_stats["MAX_DAMAGE_SOURCE"] = Keys.hash_to_string[damage_tracking_key]
		else:
			waiting_for_damage_source = true
			run_stats["MAX_DAMAGE_SOURCE"] = ""
	
	damage_source = ""


func on_player_damage_taken(player, base_damage, damage_taken:Array, args):
	# Damage into i-frame, wounderfull isn't it?
	if damage_taken.size() != 3:
		return
	
	if damage_taken[2]:
		run_stats["HITS_DODGED"] += 1
	else:
		run_stats["DAMAGE_TAKEN"] += damage_taken[1]
		if args.hitbox:
			run_stats["HITS_TAKEN"] += 1
			var result: = Unit.GetDamageValueResult.new()
			var armor_coef = RunData.get_armor_coef(player.current_stats.armor)
			result.value = max(1, round(base_damage * armor_coef)) as int if args.armor_applied else base_damage

			if result.value == damage_taken[1]:
				var dmg = base_damage - damage_taken[1]
				if dmg > 0:
					run_stats["DAMAGE_TAKEN_ARMOR"] += dmg
				else:
					run_stats["DAMAGE_TAKEN_ARMOR_NEGATIVE"] += int(abs(dmg))
		else:
			run_stats["DAMAGE_TAKEN_SELF"] += damage_taken[1]


func on_weapon_damage(pos, damage):
	if sausage:
		return
		
	run_stats["DAMAGE_DONE_WEAPONS"] += damage
	# Can happen on cleanup
	if pos >= 0 and pos < run_stats["DAMAGE_BY_WEAPON"].size():
		run_stats["DAMAGE_BY_WEAPON"][pos] += damage
		if burn:
			run_stats["DAMAGE_BY_WEAPON_BURN"][pos] += damage
		if waiting_for_damage_source:
			run_stats["MAX_DAMAGE_SOURCE"] = RunData.get_player_weapons(owner_index)[pos].my_id
			waiting_for_damage_source = false


func on_weapon_added(weapon):
	if combining_weapons:
		run_stats["DAMAGE_BY_WEAPON"].push_back(combining_weapons_damage)
		run_stats["DAMAGE_BY_WEAPON_BURN"].push_back(combining_weapons_damage_burn)
		combining_weapons_damage = 0
		combining_weapons_damage_burn = 0
	else:
		run_stats["DAMAGE_BY_WEAPON"].push_back(0)
		run_stats["DAMAGE_BY_WEAPON_BURN"].push_back(0)
	
	var dict = run_stats["WEAPONS_USAGE"]
	
	if dict.has(weapon.name):
		dict[weapon.name] += 1
	else:
		dict[weapon.name] = 1


func on_weapon_removed(weapon):
	var weapons = RunData.get_player_weapons(owner_index)
	for i in weapons.size():
		var current_weapon = weapons[i]
		if ItemService.is_same_weapon(current_weapon, weapon):
			on_weapon_index_removed(i)
			break


func remove_all_weapons()->void:
	run_stats["DAMAGE_BY_WEAPON"].clear()
	run_stats["DAMAGE_BY_WEAPON_BURN"].clear()


func on_enemy_killed(enemy):
	run_stats["KILLS_ENEMIES"] += 1
	var stats = enemy.stats
	if stats.always_drop_consumables and stats.can_drop_consumables:
		if enemy.is_loot:
			run_stats["KILLS_LOOT_ALIENS"] += 1
		elif RunData.current_wave == RunData.nb_of_waves:
			# better way to determin a boss? they all are Boss class
			if stats.health == 15000:
				wave_stats["BOSSES_KILLED"] += 1
			else:
				run_stats["KILLS_ELITES"] += 1
		else:
			run_stats["KILLS_ELITES"] += 1


func on_tree_killed():
	run_stats["KILLS_TREES"] += 1


func on_player_healed(value:int):
	if levelup or not wave_in_progress: # Fruit autocollection, do not coun't towards effective heal
		return
		
	run_stats["HP_HEALED"] += value
	if heal_source != "":
		run_stats[heal_source] += value


func on_materials_gained(value):
	if value < 0:
		run_stats["MATERIALS_SPENT"] += abs(value)
	else:
		run_stats["MATERIALS_GAINED"] += value
		if materials_source != "":
			run_stats[materials_source] += value


func on_materials_spent(value):
	run_stats["MATERIALS_SPENT"] += value
	if materials_source != "":
		run_stats[materials_source] += value


func on_materials_gained_from_weapon_crit(value: int = 1):
	run_stats["MATERIALS_GAINED_WEAPON_CRIT"] += value


func on_gold_converted(total_bonus_gold, _nb_materials_per_conversion, _nb_stats_added_per_conversion):
	if owner_index >= RunData.get_player_count(): return
	var effects = RunData.get_player_effect(Keys.convert_bonus_gold_hash,owner_index)
	run_stats["MATERIALS_CONVERTED"] = 0
	if not effects.empty() and effects[0].value > 0:
		var share = float(total_bonus_gold)/RunData.get_player_count()
		run_stats["MATERIALS_CONVERTED"] = int(floor(share/effects[0].value)*effects[0].value)


func on_shop_items_updated(item_count:int):
	run_stats["SHOP_ITEMS_BROWSED"] += item_count


func on_item_box_picked_up():
	run_stats["LOOT_BOXES"] += 1
	wave_stats["LOOT_BOXES"] += 1


func on_loot_box_taken(item):
	run_stats["LOOT_BOXES_TAKEN"] += 1
	var dict = run_stats["ITEMS_USAGE"]
	if dict.has(item.my_id):
		dict[item.my_id] += 1
	else:
		dict[item.my_id] = 1


func on_loot_box_discarded():
	run_stats["LOOT_BOXES_DISCARDED"] += 1


func on_shop_item_bought(shop_item):
	if shop_item.item_data.get_category() == Category.ITEM:
		var dict = run_stats["ITEMS_USAGE"]
		if dict.has(shop_item.item_data.my_id):
			dict[shop_item.item_data.my_id] += 1
		else:
			dict[shop_item.item_data.my_id] = 1


func get_percent_text_for_item(item)->String:
	if !tracked_items.has(item.my_id):
		return ""
		
	if !RunData.tracked_item_effects[owner_index].has(item.get_my_id_hash()):
		return ""
		
	var total = run_stats[tracked_items[item.my_id]]
	var value = RunData.tracked_item_effects[owner_index][item.get_my_id_hash()]
	# Temp fix for two values in tooltip
	if value is Array:
		return ""
	var pct = 0.0
	if total:
		pct = value * 100.0 / total
	return " (%.2f%%)" % pct


func on_wave_end():
	if owner_index >= RunData.get_player_count(): return
	var char_id = RunData.get_player_character(owner_index).my_id
	var stats
	if RunData.is_endless_run:
		stats = character_stats_endless[RunData.current_difficulty]
	else:
		stats = character_stats_normal[RunData.current_difficulty]
	
	if stats.get_value(char_id, "LOOT_BOXES_IN_A_SINGLE_WAVE", 0) < wave_stats["LOOT_BOXES"]:
		stats.update_value(char_id, "LOOT_BOXES_IN_A_SINGLE_WAVE", wave_stats["LOOT_BOXES"])
	update_character_stats(char_id, stats)
	
	if run_lost || run_won:
		run_in_progress = false
		if wave_stats["BOSSES_KILLED"] == 2:
			stats.update_value(char_id, "D5_BOSSES_KILLED", 1)
		stats.add_value(char_id, "GAMES_PLAYED", 1)
		if run_won:
			stats.add_value(char_id, "GAMES_WON", 1)
			
			var time = stats.get_value(char_id, "RUN_TIME", 0.0)
			if time == 0.0 || time > run_stats["RUN_TIME"]:
				stats.update_value(char_id, "RUN_TIME", run_stats["RUN_TIME"])
			time = stats.get_value(char_id, "WAVE20_TIME", 0.0)
			if time == 0.0 || time > wave_stats["TIME"]:
				stats.update_value(char_id, "WAVE20_TIME", wave_stats["TIME"])
		
		#Save finished runs
		var path = _save_dir() + "/character_data"
		stats.save(path)
		stats.save(path)


func on_room_clean_up(is_run_lost:bool, is_run_won:bool):
	if owner_index >= RunData.get_player_count(): return
	wave_in_progress = false
	run_lost = is_run_lost
	run_won = is_run_won
	
	var stats
	if RunData.is_endless_run:
		stats = character_stats_endless[RunData.current_difficulty]
	else:
		stats = character_stats_normal[RunData.current_difficulty]
	
	update_stats(stats)

func add_tracked_value(tracking_key, value):
	if tracking_key == Keys.item_doc_moth_hash:
		match heal_source:
			"HP_HEALED_REGEN":
				run_stats["DOC_MOTH_REGEN"] += value
			"HP_HEALED_LIFESTEAL":
				run_stats["DOC_MOTH_LIFESTEAL"] += value
			_:
				pass
	elif waiting_for_damage_source:
		var string_key = Keys.hash_to_string[tracking_key]
		if tracked_items.get(string_key, "") == "DAMAGE_DONE":
			run_stats["MAX_DAMAGE_SOURCE"] = Keys.hash_to_string[tracking_key]
			waiting_for_damage_source = false

func update_character_stats(char_id, stats:CharacterStats):
	var char_stats = [
		"stat_curse",
		"stat_max_hp",
		"stat_hp_regeneration",
		"stat_lifesteal",
		"stat_percent_damage",
		"stat_melee_damage",
		"stat_ranged_damage",
		"stat_elemental_damage",
		"stat_attack_speed",
		"stat_crit_chance",
		"stat_engineering",
		"stat_range",
		"stat_armor",
		"stat_dodge",
		"stat_speed",
		"stat_luck",
		"stat_harvesting",
	]
	
	for stat in char_stats:
		var hash_stat = Keys.generate_hash(stat)
		if stats.get_value(char_id, stat.to_upper(), 0) < Utils.get_stat(hash_stat, owner_index):
			stats.update_value(char_id, stat.to_upper(), Utils.get_stat(hash_stat, owner_index))
	
	if stats.get_value(char_id, "LEVEL", 0) < RunData.get_player_level(owner_index):
		stats.update_value(char_id, "LEVEL", RunData.get_player_level(owner_index))


func update_stats(stats:CharacterStats):
	var char_id = RunData.get_player_character(owner_index).my_id
	
	if !stats.characters.has(char_id):
		stats.characters[char_id] = init_character_stats()
	
	update_character_stats(char_id, stats)
	
	if run_lost || run_won:
		if stats.get_value(char_id, "MAX_DAMAGE", 0) < run_stats["MAX_DAMAGE"]:
			stats.update_value(char_id, "MAX_DAMAGE", run_stats["MAX_DAMAGE"])
			stats.update_value(char_id, "MAX_DAMAGE_SOURCE", run_stats["MAX_DAMAGE_SOURCE"])
		
		var items = RunData.get_player_items(owner_index)
		if stats.get_value(char_id, "ITEMS_OWNED", 0) < items.size() -1:
			stats.update_value(char_id, "ITEMS_OWNED", items.size() - 1)
		
		stats.add_value(char_id, "OVERALL_ITEMS_OWNED", items.size() - 1)
		
		var stats_to_cmp = ["DAMAGE_DONE", "DAMAGE_DONE_OVERKILL", "HP_HEALED",
			"MATERIALS_GAINED", "KILLS_ENEMIES", "LOOT_BOXES"]
		
		for stat in stats_to_cmp:
			if stats.get_value(char_id, stat, 0) < run_stats[stat]:
				stats.update_value(char_id, stat, run_stats[stat])
			stats.add_value(char_id, "OVERALL_" + stat, run_stats[stat])
		
		var dict:Dictionary = stats.characters[char_id]["WEAPONS_USAGE"]
		for key in run_stats["WEAPONS_USAGE"]:
			if dict.has(key):
				dict[key] += run_stats["WEAPONS_USAGE"][key]
			else:
				dict[key] = run_stats["WEAPONS_USAGE"][key]
		
		dict = stats.characters[char_id]["ITEMS_USAGE"]
		for key in run_stats["ITEMS_USAGE"]:
			if dict.has(key):
				dict[key] += run_stats["ITEMS_USAGE"][key]
			else:
				dict[key] = run_stats["ITEMS_USAGE"][key]


func load_tracked_items():
	for item in ItemService.items:
		if item.tracking_text == "DAMAGE_DEALT" or item.tracking_text == "EXPLOSION_DAMAGE_DEALT":
			tracked_items[item.my_id] = "DAMAGE_DONE"
		elif item.tracking_text == "HEALTH_RECOVERED":
			tracked_items[item.my_id] = "HP_HEALED"
		elif item.tracking_text == "MATERIALS_GAINED":
			tracked_items[item.my_id] = "MATERIALS_GAINED"
	for item in ItemService.characters:
		if item.tracking_text == "DAMAGE_DEALT":
			tracked_items[item.my_id] = "DAMAGE_DONE"
	tracked_items["character_chef"] = "DAMAGE_DONE"


func save():
	var path = _save_dir()
	
	var d = Directory.new()
	if !d.dir_exists(path):
		d.make_dir_recursive(path)
	
	var save_file:File = File.new()
	
	var error = save_file.open(path + "/save", File.WRITE)
	if error != OK:
		#report may be
		return
	
	var dict = { "mod_state":mod_state, "run_stats":run_stats }
	
	save_file.store_var(dict)
	save_file.close()


func load():
	# A missing slot save must not restore a ledger from an earlier loaded run.
	run_stats_saved = null
	var mod_dir = _save_dir()
	var path = mod_dir + "/save"
	
	var file = File.new()
	
	if file.file_exists(path):
		file.open(path, File.READ)
		var read_val = file.get_var(true)
		if read_val:
			mod_state = read_val.get("mod_state", init_mod_state())
			var template = init_mod_state()
			for key in template:
				if !mod_state.has(key):
					mod_state[key] = template[key]
					
			run_stats_saved = read_val.get("run_stats", null)
			if run_stats_saved:
				template = init_run_stats()
				for key in template:
					if !run_stats_saved.has(key):
						run_stats_saved[key] = template[key]
		file.close()
	else:
		mod_state = init_mod_state()
	
	for it in character_stats_normal:
		it.load(mod_dir + "/character_data")
		validate(it)
		
	for it in character_stats_endless:
		it.load(mod_dir + "/character_data")
		validate(it)


func validate(stats:CharacterStats):
	for character in stats.characters:
		for key in template_stats:
			var dict = stats.characters[character]
			if !dict.has(key):
				dict[key] = template_stats[key]


func save_run_state():
	run_stats_saved = run_stats.duplicate(true)


func reset_run_state():
	run_stats_saved = null


func resum_from_state():
	if run_stats_saved != null:
		run_stats = run_stats_saved.duplicate(true)
	elif owner_index < RunData.get_player_count():
		# Older mod saves contain no ledger for players 2-4; start these at zero.
		run_stats = init_run_stats()
		for weapon in RunData.get_player_weapons(owner_index): on_weapon_added(weapon)


func init_wave_stats()->Dictionary:
	return {
		"TIME":0,
		"LOOT_BOXES":0,
		"BOSSES_KILLED":0,
	}


func init_run_stats()->Dictionary:
	return {
		"DAMAGE_DONE":0,
		"DAMAGE_DONE_OVERKILL":0,
		"DAMAGE_DONE_WEAPONS":0,
		"DAMAGE_BY_WEAPON":[],
		"DAMAGE_BY_WEAPON_BURN":[],
		"MAX_DAMAGE":0,
		"MAX_DAMAGE_SOURCE":"",
		"KILLS_ENEMIES":0,
		"KILLS_ELITES":0,
		"KILLS_LOOT_ALIENS":0,
		"KILLS_TREES":0,
		"SPAWNED_LOOT_ALIENS":0,
		"DAMAGE_TAKEN":0,
		"DAMAGE_TAKEN_SELF":0,
		"DAMAGE_TAKEN_ARMOR":0,
		"DAMAGE_TAKEN_ARMOR_NEGATIVE":0,
		"HITS_TAKEN":0,
		"HITS_DODGED":0,
		"HP_HEALED":0,
		"HP_HEALED_FRUIT":0,
		"HP_HEALED_REGEN":0,
		"HP_HEALED_LIFESTEAL":0,
		"DOC_MOTH_REGEN":0,
		"DOC_MOTH_LIFESTEAL":0,
		"MATERIALS_GAINED":0,
		"MATERIALS_GAINED_PICKED_UP":0,
		"MATERIALS_GAINED_HARVESTING":0,
		"MATERIALS_GAINED_RECYCLING":0,
		"MATERIALS_GAINED_WEAPON_CRIT":0,
		"MATERIALS_SPENT":0,
		"MATERIALS_SPENT_SHOP":0,
		"MATERIALS_SPENT_REROLL_SHOP":0,
		"MATERIALS_SPENT_REROLL_LEVEL_UP":0,
		"MATERIALS_CONVERTED":0,
		"LOOT_BOXES":0,
		"LOOT_BOXES_TAKEN":0,
		"LOOT_BOXES_DISCARDED":0,
		"SHOP_ITEMS_BOUGHT":0,
		"SHOP_ITEMS_BROWSED":0,
		"DAMAGE_SAUSAGE":0,
		"DAMAGE_LOOTWORM":0,
		"DAMAGE_BUILDER_TURRET":0,
		"RUN_TIME":0,
		"WEAPONS_USAGE":{},
		"ITEMS_USAGE":{},
	}


func init_character_stats()->Dictionary:
	return {
		"GAMES_PLAYED":0,
		"GAMES_WON":0,
		"TOTAL_WAVES_PLAYED":0,
		"WEAPONS_USAGE":{},
		"ITEMS_USAGE":{},
	}


func init_mod_state()->Dictionary:
	return {
		"BUTTON_D5_ONLY":0,
		"BUTTON_NO_ENDLESS":0,
		"BUTTON_DIFFICULTY":0,
	}

func _save_dir() -> String:
	var base = ProgressData.SAVE_DIR + "/mod_advstats"
	return base if owner_index == 0 else base + "/player_"+str(owner_index+1)

func on_weapon_index_removed(index: int):
	if index < 0 or index >= run_stats["DAMAGE_BY_WEAPON"].size(): return
	if combining_weapons:
		combining_weapons_damage += run_stats["DAMAGE_BY_WEAPON"][index]
		combining_weapons_damage_burn += run_stats["DAMAGE_BY_WEAPON_BURN"][index]
	run_stats["DAMAGE_BY_WEAPON"].remove(index)
	run_stats["DAMAGE_BY_WEAPON_BURN"].remove(index)
