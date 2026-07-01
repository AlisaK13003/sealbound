extends Control

var panel_size: Vector2

var panel: Panel

func _setup(tab_name_string):
	panel = $Panel
	var tab_name = $Panel/Label
	
	tab_name.text = tab_name_string
	
	panel.size.x = (tab_name_string.length() * 10) + 20
	tab_name.size.x = (tab_name_string.length() * 10) + 20
	custom_minimum_size = panel.size
	size = panel.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_size = panel.size

func _update_size(new_size):
	var tab_name = $Panel/Label
	panel.size.x = new_size
	tab_name.size.x = new_size
	custom_minimum_size = panel.size
	size = panel.size

func update_highlight(highlight):
	var stylebox = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	if highlight:
		stylebox.bg_color = Color.AQUA
	else:
		stylebox.bg_color = Color.GRAY

	panel.add_theme_stylebox_override("panel", stylebox)

		
