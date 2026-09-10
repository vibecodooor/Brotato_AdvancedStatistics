extends "res://ui/menus/shop/stats_container.gd"


func _ready():
	pass

func set_focus_neighbours()->void :
	.set_focus_neighbours()
	
	var child_count = $"%StatsLabel".get_child_count()
	if (child_count == 0):
		return
	
	var child = $"%StatsLabel".get_child(0)
	var advstats_toggle: Button = child as Button if child != null else null
	if advstats_toggle:
		_primary_tab.focus_neighbour_top = advstats_toggle.get_path()
		_secondary_tab.focus_neighbour_top = advstats_toggle.get_path()
		
		if focused_tab == Tab.PRIMARY:
			if loop_focus_top:
				if show_buttons:
					advstats_toggle.focus_neighbour_top = advstats_toggle.get_path_to(last_primary_stat)

			if loop_focus_bottom:
				if show_buttons:
					last_primary_stat.focus_neighbour_bottom = last_primary_stat.get_path_to(advstats_toggle)

