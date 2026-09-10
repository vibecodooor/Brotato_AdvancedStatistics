class_name StatsRow
extends MarginContainer

var player_index = 0
var inventory_popup = null
var standalone_popup = null
var popup_content = null
var handle_popup = false

func _ready():
	$MarginContainer/HBoxContainer.set_focus_mode(Control.FOCUS_ALL)
	var _error = $MarginContainer/HBoxContainer.connect("focus_entered", self, "on_focus_entered")
	_error = $MarginContainer/HBoxContainer.connect("focus_exited",  self, "on_focus_exited")
	_error = $MarginContainer/HBoxContainer.connect("mouse_entered", self, "on_mouse_entered")
	_error = $MarginContainer/HBoxContainer.connect("mouse_exited",  self, "on_mouse_exited")


func on_focus_entered():
	$ColorRect.show()
	if popup_content:
		show_popup()


func on_focus_exited():
	$ColorRect.hide()
	if popup_content:
		hide_popup()


func on_mouse_entered():
	$MarginContainer/HBoxContainer.grab_focus()


func on_mouse_exited():
	$MarginContainer/HBoxContainer.release_focus()


func init_popup(inventory, standalone, content):
	inventory_popup = inventory
	standalone_popup = standalone
	popup_content = content


func show_popup():
	if popup_content == null or not is_instance_valid(popup_content):
		return
	
	if inventory_popup:
		inventory_popup.display_item_data(popup_content.item, self, true)
	elif standalone_popup:
		standalone_popup.set_data(popup_content, player_index)
		standalone_popup.show()
	
	handle_popup = true


func hide_popup():
	if inventory_popup:
		inventory_popup.hide()
	if standalone_popup:
		standalone_popup.hide()


func _process(_delta:float)->void:
	if handle_popup:
		if standalone_popup:
			standalone_popup.rect_global_position = get_pos()
		handle_popup = false


func get_pos()->Vector2:
	var pos = rect_global_position
	
	pos.x = pos.x + rect_size.x / 4
	pos.y = pos.y + rect_size.y
	return pos


