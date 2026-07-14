extends Control

#@onready var item_container = $VBoxContainer
#@onready var party_cards = $Party_Cards
var item_scene = "res://assets/Resources/Pause Menu/Item Menu/Display_item.tscn"
@onready var item_container = $Item_Container/Panel2/GridContainer
@onready var valuable_container = $Item_Container/Panel3/GridContainer2
@onready var quest_item_container = $Item_Container/Panel4/GridContainer3

@onready var menu_tabs = $MenuTabs
@onready var party_tabs = $MenuTabs2

@export var menu_parent : Control
@export var custom_tab_path: String
@export var display_how_many_items: int = 15 # Used strictly for mechanical view scaling

@onready var scroll_bar = $VScrollBar

var selected_item = null
var visible_tab = 0
var current_item = 0
var container_start_position: Vector2

var item_containers_parent

func _ready():
	item_containers_parent = $Item_Container
	party_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	for child in range(party_tabs.get_child_count()):
		party_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child, true)
	
	container_start_position = item_containers_parent.position
	menu_tabs._setup(["Items", "Valuables", "Quest Items"])
	menu_tabs.selection_changed.connect(tab_changed)
	
	visibility_changed.connect(_reset)
	
	for item: Items in GlobalCombatInformation.all_held_items:
		var new_node = load(item_scene)
		var new_node_instance = new_node.instantiate()
		
		new_node_instance._setup(item)
		
		if item.what_is_it & 001:
			item_container.add_child(new_node_instance)
		elif item.what_is_it & 010:
			valuable_container.add_child(new_node_instance)
		elif item.what_is_it & 100:
			quest_item_container.add_child(new_node_instance)

	for item_menu in item_containers_parent.get_children():
		item_menu.selection_updated.connect(display_item)
		for item_ in item_menu.get_child(0).get_children():
			item_.item_clicked.connect(update_selected_item.bind(true))
		if item_menu.get_index() != 0:
			item_menu.visible = false
			item_menu.disable()
			
	current_item = 0
	update_selected_item()
	tab_changed(0)
	
	for menu in item_containers_parent.get_children():
		menu._setup()
	
	GlobalCombatInformation.check_quest_progress.connect(_fully_reset)


func _reset():
	current_item = 0
	selected_item = null
	visible_tab = 0
	item_containers_parent.position = container_start_position
	update_selected_item()


func _fully_reset():
	for child_ in item_containers_parent.get_children():
		for child__ in child_.get_child(0).get_children():
			child__.queue_free()

	for item: Items in GlobalCombatInformation.all_held_items:
		var new_node = load(item_scene)
		var new_node_instance = new_node.instantiate()
		
		new_node_instance._setup(item)
		
		if item.what_is_it & 001:
			item_container.add_child(new_node_instance)
			
		elif item.what_is_it & 010:
			valuable_container.add_child(new_node_instance)
			
		elif item.what_is_it & 100:
			quest_item_container.add_child(new_node_instance)
			
	for item_menu in item_containers_parent.get_children():
		for item_ in item_menu.get_child(0).get_children():
			if not item_.item_clicked.is_connected(update_selected_item):
				item_.item_clicked.connect(update_selected_item.bind(true))
	
	tab_changed(0)
	current_item = 0
	update_selected_item()

func tab_changed(which_tab):
	if not is_visible_in_tree():
		return
	for child in range(item_containers_parent.get_child_count()):
		if which_tab == child:
			visible_tab = child
			item_containers_parent.get_child(child).enable()
			item_containers_parent.get_child(child).visible = true
		else:
			item_containers_parent.get_child(child).disable()
			item_containers_parent.get_child(child).visible = false
			
	item_containers_parent.position = container_start_position
	current_item = 0
	selected_item = null
	update_selected_item()

func update_selected_item(instance_id = null, from_click: bool = false):
	var active_container = item_containers_parent.get_child(visible_tab)
	for item_ in active_container.get_children():
		if item_.get_instance_id() == instance_id:
			current_item = item_.get_index()
			print(current_item)
			break
	print("HIASDAS")
	
	var current_container = null
	match visible_tab:
		0:
			current_container = item_container
		1:
			current_container = valuable_container
		2:
			current_container = quest_item_container
	
	for item_ in current_container.get_children():
		if item_.get_index() == current_item:
			item_.highlight(true)
		else:
			item_.highlight(false)
	display_item()

func display_item(selected_item = null):
	var current_container = null
	var mask = 0
	match visible_tab:
		0:
			current_container = item_container
			mask = 001
		1:
			current_container = valuable_container
			mask = 010
		2:
			current_container = quest_item_container
			mask = 100
			
	var count = -1
	var found_item = null
	#for item_ in GlobalCombatInformation.all_held_items:
	#	if item_.what_is_it & mask:
	#		count += 1
	#		if count == current_item:
	#			found_item = item_
	
	found_item = current_container.get_parent().current_item
	
	found_item = current_container.get_child(found_item).what_am_i
	
	if found_item != null:
		$"Item Description/VBoxContainer/Label".text = found_item.item_name
		$"Item Description/VBoxContainer/Label2".text = found_item.item_description
		$"Item Description/VBoxContainer/TextureRect".texture = found_item.item_sprite
	else:
		$"Item Description/VBoxContainer/Label".text = ""
		$"Item Description/VBoxContainer/Label2".text = ""
		$"Item Description/VBoxContainer/TextureRect".texture = null

func disable():
	for child in item_containers_parent.get_children():
		child.disable()
	
func enable():
	item_containers_parent.get_child(0).enable()
	
