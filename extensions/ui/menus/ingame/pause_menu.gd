extends "res://ui/menus/ingame/pause_menu.gd"
func _ready():
	for tracker in RunData.advstats_all():
		connect("paused", tracker, "on_game_paused")
		connect("unpaused", tracker, "on_game_unpaused")
