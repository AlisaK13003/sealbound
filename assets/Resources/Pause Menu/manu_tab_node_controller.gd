extends Control

var panel_size: Vector2

var panel: NinePatchRect
var shadow_panel: NinePatchRect
var selection_arrow: AnimatedSprite2D

func _setup(tab_name_string):
	panel = $NinePatchRect
	var tab_name = $NinePatchRect/Label
	shadow_panel = $NinePatchRect2
	tab_name.text = tab_name_string
	
	panel.size.x = (tab_name_string.length() * 10) + 20
	shadow_panel.size.x = panel.size.x
	tab_name.size.x = (tab_name_string.length() * 10) + 20
	custom_minimum_size = panel.size
	size = panel.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_size = panel.size
	
	if self.get_index() == 0:
		highlight(true)
	else:
		highlight(false)
		
	$"NinePatchRect/Horizontal List".play("default")
	$"NinePatchRect/Vertical List".play("default")


func _update_size(new_size):
	var tab_name = $NinePatchRect/Label
	panel.size.x = new_size
	shadow_panel.size.x = new_size
	tab_name.size.x = new_size
	custom_minimum_size = panel.size
	size = panel.size
	$"NinePatchRect/Horizontal List".position.x = panel.size.x / 2
	$"NinePatchRect/Vertical List".position.x = panel.size.x + 7

func highlight(highlight):
	if highlight:
		if get_parent().columns == 1:
			$"NinePatchRect/Vertical List".visible = true
			$"NinePatchRect/Horizontal List".visible = false
		else:
			$"NinePatchRect/Horizontal List".visible = true
			$"NinePatchRect/Vertical List".visible = false
	else:
		$"NinePatchRect/Horizontal List".visible = false
		$"NinePatchRect/Vertical List".visible = false
		
