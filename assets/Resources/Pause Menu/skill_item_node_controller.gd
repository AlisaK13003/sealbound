extends Control

var thing_name
var thing_quantity
var thing_bp_cost
var thing_texture

func _setup(skill_item):
	if skill_item is moves:
		thing_name = $Skills/HBoxContainer/Label2
		thing_bp_cost = $Skills/HBoxContainer/Label
		thing_texture = $Skills/HBoxContainer/TextureRect
	
		thing_name.text = skill_item.move_name
		thing_bp_cost.text = str(skill_item.mana_cost)
		thing_texture.texture = skill_item.move_sprite
	elif skill_item is Items:
		thing_name = $Items/HBoxContainer/Label2
		thing_quantity = $Items/HBoxContainer/Label
		thing_texture = $Items/HBoxContainer/TextureRect
		thing_name.text = skill_item.item_name
		thing_quantity.text = str(skill_item.stack)
		thing_texture.texture = skill_item.item_sprite
