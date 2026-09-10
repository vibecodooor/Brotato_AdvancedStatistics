extends "res://entities/units/enemies/enemy.gd"


func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null)->void:
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	
	if not (zone_min_pos == Vector2.ZERO and zone_max_pos == Vector2.ZERO):
		for tracker in RunData.advstats_all(): tracker.on_enemy_spawned(self)


func take_damage(value: int, args: TakeDamageArgs)->Array:
	var dmg = .take_damage(value, args)
	var tracker = RunData.advstats_for(args.from_player_index)
	if tracker != null and dmg.size() >= 2: tracker.on_enemy_damage_taken(dmg, args.hitbox)
	return dmg


func die(args: = Utils.default_die_args)->void:
	var was_alive = not dead;
	.die(args)
	
	var tracker = RunData.advstats_for(args.killed_by_player_index)
	if not args.cleaning_up and was_alive and tracker != null:
		tracker.on_enemy_killed(self)
