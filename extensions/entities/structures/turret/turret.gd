extends "res://entities/structures/turret/turret.gd"

var mod_tooltiptracking_key = Keys.empty_hash

func _ready():
	var tracker = RunData.advstats_for(player_index)
	tracker.on_structure_spawned(self)

func shoot()->void :
	RunData.advstats_for(player_index).damage_tracking_key = mod_tooltiptracking_key
	.shoot()
	RunData.advstats_for(player_index).damage_tracking_key = Keys.empty_hash

