extends "res://main.gd"

func _ready():
	for tracker in RunData.advstats_all(): tracker.on_wave_started()

func on_consumable_picked_up(consumable:Node, player_index:int)->void:
	RunData.advstats_for(player_index).heal_source = "HP_HEALED_FRUIT"
	if consumable.consumable_data.my_id == "consumable_item_box" || consumable.consumable_data.my_id == "consumable_legendary_item_box":
		RunData.advstats_for(player_index).on_item_box_picked_up()
	.on_consumable_picked_up(consumable, player_index)
	RunData.advstats_for(player_index).heal_source = ""


func on_levelled_up(player_index:int)->void:
	# Prevent +1 hp on levelup from tracking
	RunData.advstats_for(player_index).levelup = true
	.on_levelled_up(player_index)
	RunData.advstats_for(player_index).levelup = false


func on_gold_picked_up(gold:Node, player_index:int)->void:
	RunData.advstats_for(player_index).materials_source = "MATERIALS_GAINED_PICKED_UP"
	RunData.advstats_for(player_index).damage_source = "item_baby_elephant"
	.on_gold_picked_up(gold, player_index)
	RunData.advstats_for(player_index).materials_source = ""
	RunData.advstats_for(player_index).damage_source = ""


func manage_harvesting()->void:
	for tracker in RunData.advstats_all(): tracker.materials_source = "MATERIALS_GAINED_HARVESTING"
	.manage_harvesting()
	for tracker in RunData.advstats_all(): tracker.materials_source = ""


func on_item_box_take_button_pressed(item_data, consumable)->void:
	.on_item_box_take_button_pressed(item_data, consumable)
	RunData.advstats_for(consumable.player_index).on_loot_box_taken(item_data)


func on_item_box_discard_button_pressed(item_data, consumable)->void:
	RunData.advstats_for(consumable.player_index).materials_source = "MATERIALS_GAINED_RECYCLING"
	.on_item_box_discard_button_pressed(item_data, consumable)
	RunData.advstats_for(consumable.player_index).materials_source = ""
	RunData.advstats_for(consumable.player_index).on_loot_box_discarded()


func clean_up_room()->void :
	.clean_up_room()
	
	for tracker in RunData.advstats_all(): tracker.on_room_clean_up(_is_run_lost, _is_run_won)
	

func _on_EndWaveTimer_timeout():
	for tracker in RunData.advstats_all(): tracker.on_wave_end()
	._on_EndWaveTimer_timeout()
