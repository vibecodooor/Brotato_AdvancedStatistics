extends "res://ui/menus/shop/base_shop.gd"

func _on_item_discard_button_pressed(weapon_data: WeaponData, player_index: int)->void :
	RunData.advstats_for(player_index).materials_source = "MATERIALS_GAINED_RECYCLING"
	._on_item_discard_button_pressed(weapon_data, player_index)
	RunData.advstats_for(player_index).materials_source = ""


func _on_RerollButton_pressed(player_index: int)->void :
	RunData.advstats_for(player_index).materials_source = "MATERIALS_SPENT_REROLL_SHOP"
	._on_RerollButton_pressed(player_index)
	RunData.advstats_for(player_index).materials_source = ""


func _combine_weapon(weapon_data: WeaponData, player_index: int, is_upgrade: bool)->void :
	RunData.advstats_for(player_index).combining_weapons = true
	._combine_weapon(weapon_data, player_index, is_upgrade)
	RunData.advstats_for(player_index).combining_weapons = false

func on_shop_item_bought(shop_item: ShopItem, player_index: int)->void:
	.on_shop_item_bought(shop_item, player_index)
	RunData.advstats_for(player_index).on_shop_item_bought(shop_item)
