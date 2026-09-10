extends "res://entities/units/neutral/neutral.gd"


func take_damage(value: int, args: TakeDamageArgs)->Array:
	var dmg = .take_damage(value, args)
	
	var tracker = RunData.advstats_for(args.from_player_index)
	if tracker != null and dmg.size() >= 2: tracker.on_enemy_damage_taken(dmg, args.hitbox)
	return dmg


func die(_args: = Entity.DieArgs.new())->void:
	var was_alive = not dead
	.die(_args)
	
	var tracker = RunData.advstats_for(_args.killed_by_player_index)
	if !_args.cleaning_up and was_alive and tracker != null:
		tracker.on_tree_killed()
