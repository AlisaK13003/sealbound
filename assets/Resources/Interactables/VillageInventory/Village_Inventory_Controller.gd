extends Control

# Cycling doesn't work perfectly when moving stuff around then closing inventory
# Also currently doesn't handle inventory overflow

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

# Handles making the full inventory visible
func manage_visibility(make_visible):
	# Makes full inventory visible, and unselects all slots
	if make_visible:
		inventory_grid.get_child(selected_item).change_color(Color.AQUA)

		for slot in inventory_grid.get_children():
			slot.visible = true
			slot.change_color(Color.SKY_BLUE)
		full_inventory_visible = true
	# Hides full inventory
	else:
		# If you close the inventory while holding an item, put it in the first open slot
		if holding_item != null:
			for slot in range(Global.village_inventory.size()):
				if Global.village_inventory[slot] != null:
					Global.village_inventory[slot] = holding_item
					inventory_grid.get_child(selected_item).update_held_item(holding_item)
					holding_item = null
					break
		# Hides everything but the selected row
		for i in range(inventory_grid.get_child_count()):
			if i >= (10 * selected_row) and i <= (9 * (selected_row + 1)):
				inventory_grid.get_child(i).visible = true
			else:
				inventory_grid.get_child(i).visible = false
		inventory_grid.get_child(selected_item).change_color(Color.AQUA)
		full_inventory_visible = false
		Global.mouse_texture.texture = null

# Handles moving items around in your inventory
func swap_items(new_selected_item):
	# If placing the item back down in the same spot
	if new_selected_item == selected_item:
		inventory_grid.get_child(selected_item).update_held_item(Global.village_inventory[selected_item])
		Global.mouse_texture.texture = null
		holding_item = null
		return

	# Slot selected to place item in
	var child_to_be_swapped_with = inventory_grid.get_child(new_selected_item)
	
	# If placing the item in an empty slot
	if child_to_be_swapped_with.held_item == null:
		Global.village_inventory[new_selected_item] = Global.village_inventory[selected_item]
		child_to_be_swapped_with.update_held_item(holding_item)
		holding_item = null
		Global.mouse_texture.texture = null
		return
	
	# Otherwise, just replace stored item what's held then hold that one
	Global.village_inventory[new_selected_item] = holding_item
	holding_item = child_to_be_swapped_with.held_item

	child_to_be_swapped_with.update_held_item(Global.village_inventory[new_selected_item])
	
	Global.mouse_texture.texture = null
	Global.mouse_texture.texture = holding_item.item_texture
	
	selected_item = new_selected_item

# Has held item follow mouse cursor
func select_item(item_to_hold):
	if item_to_hold == null:
		return
	Global.mouse_texture.texture = item_to_hold.item_texture

func change_selection(new_selection):
	selected_item = new_selection
	update_selection(0)

# Handles cycling menu options when full menu isn't being displayed
func update_selection(by_amount):
	# Handles when you swap from full inventory display
	if by_amount == 0:
		for child in inventory_grid.get_children():
			child.change_color(Color.SKY_BLUE)
		inventory_grid.get_child(selected_item).change_color(Color.AQUA)
		return
	
	# If cycling from 0 to 9
	if selected_item % 10 == 0 and by_amount < 0:
		selected_item = 9 * (selected_row + 1)
	# Otherwise just mod with row length
	else:
		selected_item = clamp((selected_item + by_amount) % 10, 0, 10)
		
	# Highlight the selected inventory slot
	for i in range(inventory_grid.get_child_count()):
		if i >= (10 * selected_row) and i <= (10 * (selected_row + 1)) and i == selected_item:
			inventory_grid.get_child(i).change_color(Color.AQUA)
		else:
			inventory_grid.get_child(i).change_color(Color.SKY_BLUE)
