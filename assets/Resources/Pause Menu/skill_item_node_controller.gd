extends Control

var thing_name
var thing_quantity
var thing_bp_cost
var thing_texture

var stored_thing

signal did_a_thing(what_thing)
signal just_hovered(index)

func _setup(skill_item):
	stored_thing = skill_item
	if skill_item is moves:
		$Skills.visible = true
		
		thing_name = $Skills/HBoxContainer/Label2
		thing_bp_cost = $Skills/HBoxContainer/Label
		thing_texture = $Skills/HBoxContainer/TextureRect
	
		thing_name.text = skill_item.move_name
		thing_bp_cost.text = str(skill_item.mana_cost) + " BP"
		thing_texture.texture = skill_item.move_sprite
	elif skill_item is Items:
		$Items.visible = true
		
		thing_name = $Items/HBoxContainer/Label2
		thing_quantity = $Items/HBoxContainer/Label
		thing_texture = $Items/HBoxContainer/TextureRect
		thing_name.text = skill_item.item_name
		thing_quantity.text = str(skill_item.stack)
		thing_texture.texture = skill_item.item_sprite

func highlight(should_highlight):
	if should_highlight:
		$NinePatchRect.modulate.a = 255
	else:
		$NinePatchRect.modulate.a = 0

func was_hovered():
	just_hovered.emit(get_index())

func _on_gui_input(event):
	just_hovered.emit(get_index())
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			did_a_thing.emit(stored_thing, get_index())
