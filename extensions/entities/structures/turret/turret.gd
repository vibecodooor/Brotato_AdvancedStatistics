extends "res://entities/structures/turret/turret.gd"

var mod_tooltiptracking_key = Keys.empty_hash

func _ready():
	var tracker = get_tree().get_root().get_node("ModLoader/meinfesl-AdvancedStatistics/StatsTracker")
	tracker.on_structure_spawned(self)

func shoot()->void :
	RunData.mod_advstats.damage_tracking_key = mod_tooltiptracking_key
	.shoot()
	RunData.mod_advstats.damage_tracking_key = Keys.empty_hash

