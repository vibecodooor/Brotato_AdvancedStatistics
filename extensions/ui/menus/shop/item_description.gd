extends "res://ui/menus/shop/item_description.gd"


func set_item(item_data: ItemParentData, player_index: int, item_count: = 1)->void:
	
	if item_data.my_id == "item_scared_sausage":
		RunData.tracked_item_effects[player_index][Keys.item_scared_sausage_hash] = RunData.advstats_for(player_index).run_stats["DAMAGE_SAUSAGE"]
	
	.set_item(item_data, player_index, item_count)
	
	if item_data.tracking_text == "":
		return
	
	var pct_text = RunData.advstats_for(player_index).get_percent_text_for_item(item_data)
	if pct_text != "":
		# Temp fix for two values in tooltip
		var val = RunData.tracked_item_effects[player_index][item_data.get_my_id_hash()]
		if val is Array:
			return
		var str_to_find = "[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(item_data.tracking_text, [Text.get_formatted_number(val)]) + "[/color]"
		var last = get_effects().get_children().back()
		var text:String = last.text_descr.bbcode_text
		var index:int = text.find(str_to_find)
		if index != -1:
			var str_to_insert = "[color=#%s]%s[/color]" % [Utils.SECONDARY_FONT_COLOR.to_html(), pct_text]
			last.text_descr.bbcode_text = text.insert(index + str_to_find.length(), str_to_insert)
