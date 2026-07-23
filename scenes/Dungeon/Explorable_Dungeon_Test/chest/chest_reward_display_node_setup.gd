extends Control

func _setup(item, _type):
	var item_name = $HBoxContainer/Label
	var item_texture = $HBoxContainer/TextureRect
	if item is Items:
		item_name.text = item.item_name
		item_texture.texture = item.item_sprite
	elif item is weapon:
		item_name.text = item.weapon_name
		item_texture.texture = item.weapon_texture
	elif item is equipment:
		item_name.text = item.equipment_name
		item_texture.texture = item.equipment_sprite
	else:
		item_name.text = "Unknown Reward"
		item_texture.texture = null
