extends Control

var item_name: String

var holding_item: bool 
var held_item: inventory_items

var slot_number: int
var node_parent

var stylebox: StyleBox

@onready var texture_node: TextureRect = $TextureRect
@onready var attached_panel: Panel = $Panel
@onready var item_count_label: Label = $Quantity

# Stores the active stylebox style
func _ready():
	var current_style = attached_panel.get_theme_stylebox("panel")
	
	if stylebox is StyleBoxFlat:
		stylebox = current_style.duplicate()
	else:
		stylebox = StyleBoxFlat.new()
		
	attached_panel.add_theme_stylebox_override("panel", stylebox)

# Upon player loading in, setup necessary information
func _setup(what_child_am_i, parent):
	slot_number = what_child_am_i
	held_item = Global.village_inventory[what_child_am_i].duplicate(true) if Global.village_inventory[what_child_am_i] != null else null
	if held_item != null:
		holding_item = true
		held_item.amount_held = Global.village_inventory[what_child_am_i].amount_held
		item_count_label.text = str(held_item.amount_held) + "x"
	else:
		item_count_label.text = "0x"

	node_parent = parent

	texture_node.texture = held_item.item_texture if held_item != null else null
		
func change_color(new_color):
	if not is_node_ready():
		await ready
	
	stylebox.bg_color = new_color

func update_held_item(new_item):
	held_item = new_item
	if held_item == null:
		texture_node.texture = null
		return
	texture_node.texture = held_item.item_texture
	item_count_label.text = str(new_item.amount_held) + "x"

func empty_cell():
	held_item = null
	texture_node.texture = null
	holding_item = false
	item_name = ""
	item_count_label.text = "0x"

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("Mouse_Left_Click"):
		if Global.is_in_menu:
			node_parent.open_sell_menu.emit(held_item, slot_number)
			return
		if not node_parent.full_inventory_visible:
			node_parent.change_selection(slot_number)
		else:
			if node_parent.holding_item != null:
				node_parent.swap_items(slot_number)
				return
			if held_item != null:
				node_parent.selected_item = slot_number
				held_item.amount_held = Global.village_inventory[slot_number].amount_held
				node_parent.holding_item = held_item
				Global.mouse_texture.texture = held_item.item_texture
				Global.remove_from_inventory(slot_number)
				empty_cell()
	if event.is_action_pressed("Mouse_Right_Click"):
		if node_parent.holding_item != null:
			if held_item == null:
				if node_parent.holding_item.amount_held == 1:
					Global.added_just_one_item(node_parent.holding_item, slot_number)
					Global.mouse_texture.texture = null
					node_parent.holding_item = null
					return
				else:
					node_parent.holding_item.amount_held -= 1
					Global.added_just_one_item(node_parent.holding_item.duplicate(true), slot_number)
					if node_parent.holding_item.amount_held == 0:
						Global.mouse_texture.texture = null
						node_parent.holding_item = null
					return
			if held_item.item_resource_path != node_parent.holding_item.item_resource_path or held_item.amount_held == held_item.stack_amount:
				return
			else:
				Global.added_just_one_item(node_parent.holding_item, slot_number)
				node_parent.holding_item.amount_held -= 1
				if node_parent.holding_item.amount_held == 0:
					Global.mouse_texture.texture = null
					node_parent.holding_item = null
					return
