extends Control

var panel_size: Vector2

var panel: NinePatchRect
var shadow_panel: NinePatchRect
var selection_arrow: TextureRect

func _setup(tab_name_string):
	panel = $NinePatchRect
	var tab_name = $NinePatchRect/Label
	shadow_panel = $NinePatchRect2
	selection_arrow = $NinePatchRect/TextureRect
	tab_name.text = tab_name_string
	
	panel.size.x = (tab_name_string.length() * 10) + 20
	shadow_panel.size.x = panel.size.x
	tab_name.size.x = (tab_name_string.length() * 10) + 20
	custom_minimum_size = panel.size
	size = panel.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_size = panel.size
	selection_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_arrow.position.x = panel.size.x / 2
	
	if self.get_index() == 0:
		update_highlight(true)
	else:
		update_highlight(false)


func _update_size(new_size):
	var tab_name = $NinePatchRect/Label
	panel.size.x = new_size
	shadow_panel.size.x = new_size
	tab_name.size.x = new_size
	custom_minimum_size = panel.size
	size = panel.size
	selection_arrow.position.x = panel.size.x / 2


func update_highlight(highlight):
	if highlight:
		if get_parent().columns > 1:
			$NinePatchRect/TextureRect.visible = true
			$NinePatchRect/TextureRect2.visible = false
		else:
			$NinePatchRect/TextureRect2.visible = true
			$NinePatchRect/TextureRect.visible = false
	else:
		$NinePatchRect/TextureRect2.visible = false
		$NinePatchRect/TextureRect.visible = false
		
