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
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in range(inventory_grid.get_child_count()):
		inventory_grid.get_child(child)._setup(child, self)
	Global.inventory_updated.connect(update_inventory_slot)
	update_selection(0)

# Handles making the full inventory visible
func manage_visibility(make_visible):
	# Makes full inventory visible, and unselects all slots
	if make_visible:
		visible = true
		mouse_filter = Control.MOUSE_FILTER_PASS
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
					Global.added_to_inventory(holding_item, slot)
					holding_item = null
					break
		# Hides everything but the selected row
		for i in range(inventory_grid.get_child_count()):
			if i >= (10 * selected_row) and i <= (9 * (selected_row + 1)):
				inventory_grid.get_child(i).visible = true
			else:
				inventory_grid.get_child(i).visible = false
		inventory_grid.get_child(selected_item).change_color(Color.AQUA)
		if inventory_grid.get_child(selected_item).held_item != null:
			Global.holding_item = holding_item
			Global.player_head_sprite = inventory_grid.get_child(selected_item).held_item.over_the_head_texture if inventory_grid.get_child(selected_item).held_item.over_the_head_texture != null else null
		Global.item_is_in_slot = selected_item
		full_inventory_visible = false
		Global.mouse_texture.texture = null
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE

# Handles moving items around in your inventory
func swap_items(new_selected_item):
	# Slot selected to place item in
	var child_to_be_swapped_with = inventory_grid.get_child(new_selected_item)
	
	# If placing the item in an empty slot
	if child_to_be_swapped_with.held_item == null:
		Global.village_inventory[new_selected_item] = null
		var retval = Global.added_to_inventory(holding_item, new_selected_item)
		if retval != null:
			holding_item = retval
			return
		holding_item = null
		Global.mouse_texture.texture = null
		return
	
	# Otherwise, just replace stored item what's held then hold that one
	if child_to_be_swapped_with.held_item.item_resource_path == holding_item.item_resource_path:
		var amount_already_present = Global.village_inventory[new_selected_item].amount_held
		if amount_already_present == Global.village_inventory[new_selected_item].stack_amount:
			var temp = amount_already_present - holding_item.amount_held
			holding_item.amount_held += temp
			Global.remove_from_inventory_n_times(new_selected_item, temp)
			return
		elif holding_item.amount_held == child_to_be_swapped_with.held_item.stack_amount:
			var temp = holding_item.amount_held - Global.village_inventory[new_selected_item].amount_held 
			holding_item.amount_held -= temp
			Global.village_inventory[new_selected_item].amount_held = Global.village_inventory[new_selected_item].stack_amount
			Global.inventory_updated.emit(new_selected_item)
			return

		var retval = Global.added_to_inventory(holding_item, new_selected_item)
		if retval != null:
			holding_item = retval
			return
		holding_item = null
		Global.mouse_texture.texture = null
		return
		
	Global.village_inventory[new_selected_item] = holding_item
	holding_item = child_to_be_swapped_with.held_item

	child_to_be_swapped_with.update_held_item(Global.village_inventory[new_selected_item])
	
	Global.mouse_texture.texture = holding_item.item_texture
	Global.holding_item = holding_item
	
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
		if inventory_grid.get_child(selected_item).held_item != null:
			Global.player_head_sprite = inventory_grid.get_child(selected_item).held_item.over_the_head_texture if inventory_grid.get_child(selected_item).held_item.over_the_head_texture != null else null
		else:
			Global.player_head_sprite = null
		Global.holding_item = inventory_grid.get_child(selected_item).held_item
		Global.item_is_in_slot = selected_item
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
			if inventory_grid.get_child(selected_item).held_item != null:
				Global.player_head_sprite = inventory_grid.get_child(selected_item).held_item.over_the_head_texture if inventory_grid.get_child(selected_item).held_item.over_the_head_texture != null else null
			else:
				Global.player_head_sprite = null
			Global.holding_item = inventory_grid.get_child(selected_item).held_item
			Global.item_is_in_slot = selected_item

		else:
			inventory_grid.get_child(i).change_color(Color.SKY_BLUE)

func update_inventory_slot(slot_to_update):
	var child_to_update = inventory_grid.get_child(slot_to_update)
	if child_to_update.held_item == Global.village_inventory[slot_to_update]:
		child_to_update.held_item = null
		child_to_update.holding_item = false
	if Global.village_inventory[slot_to_update] == null:
		child_to_update.empty_cell()
	else:
		child_to_update.update_held_item(Global.village_inventory[slot_to_update])
