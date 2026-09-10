extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"


func _on_RerollButton_pressed()->void:
	RunData.advstats_for(player_index).materials_source = "MATERIALS_SPENT_REROLL_LEVEL_UP"
	._on_RerollButton_pressed()
	RunData.advstats_for(player_index).materials_source = ""
