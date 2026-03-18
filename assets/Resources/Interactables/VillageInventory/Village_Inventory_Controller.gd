extends Control

@onready var inventory_grid = $GridContainer
@onready var settings_button = $Button

var selected_row = 0
var selected_item = 0

var full_inventory_visible: bool

var holding_item

var stylebox : StyleBoxFlat

func _ready():
	update_selection(0)
	for child in range(inventory_grid.get_child_count()):
		inventory_grid.get_child(child)._setup(child, self)

func manage_visibility(make_visible):
	if make_visible:
		inventory_grid.get_child(selected_item).change_color(Color.AQUA)

		for slot in inventory_grid.get_children():
			slot.visible = true
			slot.change_color(Color.SKY_BLUE)
		full_inventory_visible = true
	else:
		if holding_item != null:
			for slot in range(Global.village_inventory.size()):
				if Global.village_inventory[slot] != null:
					Global.village_inventory[slot] = holding_item
					inventory_grid.get_child(selected_item).update_held_item(holding_item)
					holding_item = null
					break
		for i in range(inventory_grid.get_child_count()):
			if i >= (10 * selected_row) and i <= (9 * (selected_row + 1)):
				inventory_grid.get_child(i).visible = true
			else:
				inventory_grid.get_child(i).visible = false
		inventory_grid.get_child(selected_item).change_color(Color.AQUA)
		full_inventory_visible = false
		Global.mouse_texture.texture = null

func swap_items(new_selected_item):
	if new_selected_item == selected_item:
		inventory_grid.get_child(selected_item).update_held_item(Global.village_inventory[selected_item])
		Global.mouse_texture.texture = null
		holding_item = null
		return

	var child_to_be_swapped_with = inventory_grid.get_child(new_selected_item)

	if child_to_be_swapped_with.held_item == null:
		Global.village_inventory[new_selected_item] = Global.village_inventory[selected_item]
		child_to_be_swapped_with.update_held_item(holding_item)
		holding_item = null
		Global.mouse_texture.texture = null
		return
	
	Global.village_inventory[new_selected_item] = holding_item
	holding_item = child_to_be_swapped_with.held_item

	child_to_be_swapped_with.update_held_item(Global.village_inventory[new_selected_item])
	
	Global.mouse_texture.texture = null
	Global.mouse_texture.texture = holding_item.item_texture
	
	selected_item = new_selected_item
	
	var j = 0
	for child in inventory_grid.get_children():
		if child.held_item == null:
			continue
		j += 1
	print(j)
	
	var i = 0
	for item in Global.village_inventory:
		if item == null:
			continue
		i += 1
	print(i)
	
func select_item(item_to_hold):
	if item_to_hold == null:
		return
	Global.mouse_texture.texture = item_to_hold.item_texture
	pass

func change_selection(new_selection):
	selected_item = new_selection
	update_selection(0)

func update_selection(by_amount):
	if by_amount == 0:
		for child in inventory_grid.get_children():
			child.change_color(Color.SKY_BLUE)
		inventory_grid.get_child(selected_item).change_color(Color.AQUA)
		print("HI")
		return
		
	if selected_item % 10 == 0 and by_amount < 0:
		selected_item = 9 * (selected_row + 1)
	else:
		selected_item = clamp((selected_item + by_amount) % 10, 0, 10)
	for i in range(inventory_grid.get_child_count()):
		if i >= (10 * selected_row) and i <= (10 * (selected_row + 1)) and i == selected_item:
			inventory_grid.get_child(i).change_color(Color.AQUA)
		else:
			inventory_grid.get_child(i).change_color(Color.SKY_BLUE)
