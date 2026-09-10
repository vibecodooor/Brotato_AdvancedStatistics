extends "res://entities/units/player/player.gd"


func take_damage(value: int, args: TakeDamageArgs)->Array:
	RunData.advstats_for(player_index).damage_source = "item_riposte"
	var dmg = .take_damage(value, args)
	RunData.advstats_for(player_index).on_player_damage_taken(self, value, dmg, args)
	RunData.advstats_for(player_index).damage_source = ""
	return dmg


func heal(value:int, is_from_torture:bool = false)->int:
	var amount = .heal(value, is_from_torture)
	if amount > 0:
		RunData.advstats_for(player_index).on_player_healed(amount)
	return amount


func on_health_regen(loop_count:int)->void:
	RunData.advstats_for(player_index).heal_source = "HP_HEALED_REGEN"
	.on_health_regen(loop_count)
	RunData.advstats_for(player_index).heal_source = ""


func on_lifesteal_effect(value:int)->void:
	RunData.advstats_for(player_index).heal_source = "HP_HEALED_LIFESTEAL"
	.on_lifesteal_effect(value)
	RunData.advstats_for(player_index).heal_source = ""

func on_heal_over_time_timer_timeout()->void :
	RunData.advstats_for(player_index).heal_source = "HP_HEALED_FRUIT"
	.on_heal_over_time_timer_timeout()
	RunData.advstats_for(player_index).heal_source = ""
