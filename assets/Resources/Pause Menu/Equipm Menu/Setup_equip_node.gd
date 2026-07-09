extends Control

signal node_pressed

var stored_item

func _setup(item, is_weapon):
	stored_item = item
	var equip_name = $Panel/Equip_Name
	var description = $"Panel/Equip_Name/Equip Description"
	var stats_ = $Panel/Equip_Name/Stats
	var equip_texture = $TextureRect
	
	var item_info = item.return_stuff()
	
	equip_name.text = item_info["name"]
	description.text = item_info["description"]
	equip_texture.texture = item_info["texture"]
	stats_.text = item.get_stat_string()
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_update_selection(true)
			node_pressed.emit(self.get_instance_id(), stored_item)

func move_left(index):
	$Panel.position.x -= index * 6
	$TextureRect.position.x -= index * 6

func _update_selection(selected):
	if selected:
		$TextureRect2.visible = true
	else:
		$TextureRect2.visible = false
