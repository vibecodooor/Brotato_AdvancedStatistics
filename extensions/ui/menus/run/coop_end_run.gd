extends "res://ui/menus/run/coop_end_run.gd"
var advstats_panel
var advstats_menu
var advstats_tabs = []
func _ready():
	advstats_panel = PanelContainer.new()
	advstats_panel.name = "CoopStatistics"
	add_child(advstats_panel)
	advstats_panel.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	var layout = VBoxContainer.new()
	advstats_panel.add_child(layout)
	var tabs = HBoxContainer.new()
	layout.add_child(tabs)
	for i in RunData.get_player_count():
		var button = MyMenuButton.new()
		button.text = str(i+1)+": "+tr(RunData.get_player_character(i).name)
		button.connect("pressed",self,"advstats_show",[i])
		tabs.add_child(button)
		advstats_tabs.append(button)
	var back = MyMenuButton.new()
	back.text = tr("BACK")
	back.connect("pressed",self,"advstats_close")
	tabs.add_child(back)
	advstats_menu = load("res://mods-unpacked/meinfesl-AdvancedStatistics/ui/stats_menu.tscn").instance()
	advstats_menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(advstats_menu)
	var popup = load("res://ui/menus/ingame/item_panel_ui.tscn").instance()
	add_child(popup)
	popup.hide()
	advstats_menu.standalone_popup = popup
	advstats_panel.hide()
	var entry = MyMenuButton.new()
	entry.text = "Co-op Statistics"
	_new_run_button.get_parent().add_child(entry)
	entry.connect("pressed",self,"advstats_show",[0])
func advstats_show(index: int):
	advstats_menu.player_index = index
	advstats_menu.weapons_container = player_containers[index].weapons_container.get_node("ScrollSizeContainer/ScrollContainer/Elements")
	advstats_menu.items_container = player_containers[index].items_container.get_node("ScrollSizeContainer/ScrollContainer/Elements")
	advstats_menu.inventory_popup = item_popups[index]
	advstats_panel.show()
	advstats_menu.build_statistics()
	advstats_tabs[index].grab_focus()
func advstats_close():
	advstats_menu.standalone_popup.hide()
	advstats_panel.hide()
	_new_run_button.grab_focus()
