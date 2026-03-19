extends Control

var item_name: String

var holding_item: bool 
var held_item: inventory_items

var slot_number: int
var node_parent

var stylebox: StyleBox

@onready var texture_node: TextureRect = $TextureRect
@onready var attached_panel: Panel = $Panel

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

func empty_cell():
	held_item = null
	texture_node.texture = null
	holding_item = false
	item_name = ""

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	#if event.is_action_pressed("Mouse_Right_Click"):
		#print("I am number ", slot_number)
	if event.is_action_pressed("Mouse_Left_Click"):
		if not node_parent.full_inventory_visible:
			node_parent.change_selection(slot_number)
		else:
			if node_parent.holding_item != null:
				node_parent.swap_items(slot_number)
				return
			if held_item != null:
				node_parent.selected_item = slot_number
				node_parent.holding_item = held_item
				Global.mouse_texture.texture = held_item.item_texture
				empty_cell()
