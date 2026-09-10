extends "res://weapons/weapon.gd"

func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int)->void :
	RunData.advstats_for(_parent.player_index).exploding_weapon = self
	._on_Hitbox_hit_something(thing_hit, damage_dealt)
	RunData.advstats_for(_parent.player_index).exploding_weapon = null
	RunData.advstats_for(_parent.player_index).waiting_for_damage_source = false


func mod_advstat_count_damage(_thing_hit: Node, damage_dealt: int, _hitbox: Hitbox):
	RunData.add_weapon_dmg_dealt(weapon_pos, damage_dealt, _parent.player_index)


func on_added_gold_on_crit(_gold_added: int)->void :
	.on_added_gold_on_crit(_gold_added)
	RunData.advstats_for(_parent.player_index).on_materials_gained_from_weapon_crit(_gold_added)
