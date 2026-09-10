extends "res://ui/menus/ingame/ingame_main_menu.gd"

var mod_advstats_button
var mod_advstats_menu
onready var mod_advstats_vbox = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer


func _ready():
	var stats_label = $"%StatsContainer"/MarginContainer/VBoxContainer2/StatsLabel
	var button = load("res://mods-unpacked/meinfesl-AdvancedStatistics/ui/stats_button.tscn").instance()
	mod_advstats_button = button
	stats_label.add_child(button)
	
	var _error = button.connect("pressed", self, "mod_advstats_button_pressed")

	var standalone_popup = load("res://ui/menus/ingame/item_panel_ui.tscn").instance()
	standalone_popup.hide()
	add_child(standalone_popup)

	mod_advstats_menu = load("res://mods-unpacked/meinfesl-AdvancedStatistics/ui/stats_menu.tscn").instance()
	mod_advstats_menu.hide()

	mod_advstats_menu.weapons_container = $"%WeaponsContainer"/ScrollSizeContainer/ScrollContainer/Elements
	mod_advstats_menu.items_container = $"%ItemsContainer"/ScrollSizeContainer/ScrollContainer/Elements
	mod_advstats_menu.inventory_popup = $ItemPopup
	mod_advstats_menu.standalone_popup = standalone_popup

	$MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer.add_child_below_node(mod_advstats_vbox, mod_advstats_menu)

	_error = get_parent().get_parent().connect("paused", mod_advstats_menu, "build_statistics")
	
	$"%StatsContainer".set_focus_neighbours()


func mod_advstats_button_pressed():
	if mod_advstats_vbox.visible:
		var x = mod_advstats_vbox.rect_size.x
		mod_advstats_vbox.hide()
		mod_advstats_menu.rect_min_size.x = x
		var size_diff = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer.rect_size.y - $"%StatsContainer".rect_size.y
		mod_advstats_menu.build_statistics()
		mod_advstats_menu.add_constant_override("margin_top", size_diff / 2)
		mod_advstats_menu.add_constant_override("margin_bottom", size_diff / 2)
		mod_advstats_menu.show()
		mod_advstats_button.text = "-"
	else:
		mod_advstats_menu.hide()
		mod_advstats_vbox.show()
		mod_advstats_button.text = "+"

func _set_player_index(p_player_index: int):
	._set_player_index(p_player_index)
	if is_instance_valid(mod_advstats_menu):
		mod_advstats_menu.player_index = p_player_index
		mod_advstats_menu.build_statistics()
