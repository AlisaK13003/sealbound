extends Control

func _setup(item, type):
	var item_name = $HBoxContainer/Label
	var item_texture = $HBoxContainer/TextureRect
	match type:
		# Standard item
		0:
			item_name.text = item.item_name
			item_texture.texture = item.item_sprite
		# Weapon:
		1:
			pass
		# Equipment:
		2:
			pass
