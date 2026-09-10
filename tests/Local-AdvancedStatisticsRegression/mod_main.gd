extends Node
var player_count=4
var checks=0
var failures=[]
func _ready():
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--players="): player_count=int(arg.get_slice("=",1))
	if not "--advstats-coop-test" in OS.get_cmdline_args(): return
	if OS.get_user_data_dir().get_file() != "AdvancedStatistics-Isolated-Test":
		push_error("Use the disposable AdvancedStatistics-Isolated-Test user directory")
		get_tree().quit(2)
		return
	if player_count < 1 or player_count > 4:
		get_tree().quit(2)
		return
	call_deferred("run_tests")
func check(ok,label):
	checks+=1
	if not ok: failures.append(label)
func run_tests():
	yield(get_tree().create_timer(.3),"timeout")
	RunData.reset()
	RunData.set_player_count(player_count,true)
	RunData.set_coop_run(player_count > 1)
	CoopService.connected_players=[[0,0],[1,0],[2,0],[3,0]].slice(0,player_count-1)
	TempStats.reset()
	LinkedStats.reset()
	var ids=["character_well_rounded","character_well_rounded","character_well_rounded","character_well_rounded"]
	for i in player_count:
		for c in ItemService.characters:
			if c.my_id==ids[i]:
				RunData.add_character(c,i)
				for n in i+1: RunData.add_weapon(c.starting_weapons[0],i)
	RunData.add_starting_items_and_weapons()
	for i in player_count:
		var tracker=RunData.advstats_for(i)
		check(tracker.owner_index==i,"tracker owner")
		check(tracker.run_stats.DAMAGE_BY_WEAPON.size()==RunData.get_player_weapons(i).size(),"separate weapon lists")
		RunData.add_weapon_dmg_dealt(0,(i+1)*101,i)
		RunData.add_gold((i+1)*100,i)
		RunData.add_stat(Keys.stat_max_hp_hash,1000,i)
	for i in player_count:
		var tracker=RunData.advstats_for(i)
		check(tracker.run_stats.DAMAGE_BY_WEAPON[0]==(i+1)*101,"separate weapon damage")
		tracker.save_run_state()
		var before=tracker.run_stats.DAMAGE_DONE_WEAPONS
		RunData.add_weapon_dmg_dealt(0,9,i)
		check(tracker.run_stats_saved.DAMAGE_DONE_WEAPONS==before,"snapshot independent")
		tracker.save()
		tracker.run_stats_saved=null
		tracker.load()
		tracker.resum_from_state()
		check(tracker.run_stats.DAMAGE_DONE_WEAPONS==before+9,"disk round trip owner")
	# An old solo save has no ledgers for additional co-op slots.
	for i in player_count:
		var tracker = RunData.advstats_for(i)
		var snapshot = tracker.run_stats.duplicate(true)
		tracker.run_stats_saved = null
		tracker.resum_from_state()
		check(tracker.run_stats.DAMAGE_BY_WEAPON.size() == RunData.get_player_weapons(i).size(), "legacy inventory slots")
		check(tracker.run_stats.DAMAGE_DONE_WEAPONS == 0, "legacy ledger starts at zero")
		tracker.run_stats = snapshot
		tracker.save_run_state()
	check(RunData.advstats_for(-1) == null and RunData.advstats_for(4) == null, "invalid owners are not player one")
	Utils.reset_stat_caches()
	var converter=Effect.new()
	converter.value=10
	var original_conversion=RunData.get_player_effects(0)[Keys.convert_bonus_gold_hash]
	RunData.get_player_effects(0)[Keys.convert_bonus_gold_hash]=[converter]
	for i in player_count:
		var tracker=RunData.advstats_for(i)
		tracker.on_gold_converted(player_count*21,10,1)
		check(tracker.run_stats.MATERIALS_CONVERTED==(20 if i==0 else 0),"shared materials converted only for owner")
		var before=tracker.run_stats.MATERIALS_GAINED_WEAPON_CRIT
		tracker.on_materials_gained_from_weapon_crit(3)
		check(tracker.run_stats.MATERIALS_GAINED_WEAPON_CRIT==before+3,"crit income keeps actual amount")
	RunData.get_player_effects(0)[Keys.convert_bonus_gold_hash]=original_conversion
	RunData.init_elites_spawn()
	RunData.init_bosses_spawn()
	DebugService.invulnerable=true
	get_tree().change_scene(MenuData.game_scene)
	yield(get_tree().create_timer(8),"timeout")
	var main=get_tree().current_scene
	check(main._players.size()==player_count,"expected number of live players")
	for i in player_count:
		var p=main._players[i]
		var tracker=RunData.advstats_for(i)
		p.current_stats.health=p.max_stats.health-50
		var before=tracker.run_stats.HP_HEALED
		p.on_healing_effect(3+i)
		check(tracker.run_stats.HP_HEALED==before+3+i,"healing attributed")
		# Spawn a dedicated target so wave timing and random enemy deaths cannot
		# remove the target before the synchronous ownership assertions.
		var spawn_args = EntitySpawner.SpawnEntityArgs.new(Vector2(400,400), EntityType.ENEMY)
		var target = main._entity_spawner.spawn_entity(load("res://entities/units/enemies/chaser/chaser.tscn"), spawn_args)
		var enemies = [target] if target != null else []
		check(not enemies.empty(),"real combat enemy available")
		if not enemies.empty():
			enemies[0].current_stats.health=10000
			var other=RunData.advstats_for((i+1)%player_count).run_stats.DAMAGE_DONE
			var damage_before=tracker.run_stats.DAMAGE_DONE
			var args=TakeDamageArgs.new(i)
			args.bypass_invincibility=true
			var result=enemies[0].take_damage(100,args)
			check(tracker.run_stats.DAMAGE_DONE==damage_before+result[1],"actual enemy hit owner")
			if player_count > 1: check(RunData.advstats_for((i+1)%player_count).run_stats.DAMAGE_DONE==other,"no cross-player damage")
	var menu=main.find_node("MainMenu",true,false)
	for i in player_count:
		menu.init(i)
		menu.mod_advstats_button_pressed()
		yield(get_tree(),"idle_frame")
		check(menu.mod_advstats_menu.tracker.owner_index==i,"statistics follows selected player")
		menu.mod_advstats_button_pressed()

	main.clean_up_room()
	RunData.current_wave=6
	for i in [0,2]:
		if i<player_count: RunData.add_item(ItemService.get_item_from_id(Keys.item_piggy_bank_hash),i)
	for i in player_count:
		RunData.add_gold(1000,i)
		RunData.get_player_effects(i)[Keys.generate_hash("extra_enemies_next_wave")]=[["res://zones/common/bait/group_bait.tres",i+1]]
	get_tree().change_scene(RunData.get_shop_scene_path())
	yield(get_tree().create_timer(.5),"timeout")
	var shop=get_tree().current_scene
	for i in player_count:
		var before=RunData.advstats_for(i).run_stats.SHOP_ITEMS_BROWSED
		shop._on_RerollButton_pressed(i)
		check(RunData.advstats_for(i).run_stats.SHOP_ITEMS_BROWSED>before,"reroll attributed")
		for item in RunData.get_player_items(i):shop._get_item_popup(i).display_item_data(item,shop._get_go_button(i),true)
		for weapon in RunData.get_player_weapons(i):shop._get_item_popup(i).display_item_data(weapon,shop._get_go_button(i),true)
		if i>0:
			var weapons_before=RunData.get_player_weapons(i).size()
			var total_before=RunData.advstats_for(i).run_stats.DAMAGE_DONE_WEAPONS
			shop._combine_weapon(RunData.get_player_weapons(i)[0],i,false)
			check(RunData.get_player_weapons(i).size()==weapons_before-1,"combine owner weapon count")
			check(RunData.advstats_for(i).run_stats.DAMAGE_BY_WEAPON.size()==weapons_before-1,"combine ledger matches inventory")
			check(RunData.advstats_for(i).run_stats.DAMAGE_DONE_WEAPONS==total_before,"combine preserves damage")
	ProgressData.save_run_state(shop._shop_items)
	ProgressData.save()
	for i in player_count:
		var tracker=RunData.advstats_for(i)
		check(JSON.print(tracker.run_stats_saved)==JSON.print(tracker.run_stats),"shop snapshot current")
	if player_count > 1:
		get_tree().change_scene("res://ui/menus/run/coop_end_run.tscn")
		yield(get_tree().create_timer(.3),"timeout")
		var ending=get_tree().current_scene
		for i in player_count:
			ending.advstats_show(i)
			yield(get_tree(),"idle_frame")
			check(ending.advstats_menu.tracker.owner_index==i,"coop end statistics owner")
			ending.advstats_close()
	for i in player_count:
		var tracker = RunData.advstats_for(i)
		RunData.remove_all_weapons(i)
		check(tracker.run_stats.DAMAGE_BY_WEAPON.empty() and tracker.run_stats.DAMAGE_BY_WEAPON_BURN.empty(), "clear both weapon ledgers")
	print("ADVSTATS_RESULT ",JSON.print({"checks":checks,"failures":failures}))
	get_tree().quit(0 if failures.empty() else 1)
