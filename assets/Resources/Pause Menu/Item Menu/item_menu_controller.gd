extends Control

#@onready var item_container = $VBoxContainer
#@onready var party_cards = $Party_Cards
var item_scene = "res://assets/Resources/Pause Menu/Item Menu/Display_item.tscn"
@onready var item_container = $Container/GridContainer
@onready var valuable_container = $Container/GridContainer2
@onready var quest_item_container = $Container/GridContainer3

@onready var menu_tabs = $MenuTabs

var selected_item = 0

@export var menu_parent : Control

func _reset():
	item_container.visible = true
	valuable_container.visible = false
	quest_item_container.visible = false

func _ready():
	menu_tabs._setup(["Items", "Valuables", "Quest Items"])
	menu_tabs.selection_changed.connect(tab_changed)
	
	visibility_changed.connect(_reset)
	
	var flip_i: bool = false
	var flip_v: bool = false
	var flip_q: bool = false
	for item: Items in GlobalCombatInformation.all_held_items:
		var new_node = load(item_scene)
		var new_node_instance = new_node.instantiate()
		
		new_node_instance._setup(item)
		
		if item.what_is_it & 001:
			item_container.add_child(new_node_instance)
			if new_node_instance.get_index() % item_container.columns == 0:
				if flip_i:
					flip_i = false
				else:
					flip_i = true
			new_node_instance.swap_orientation(flip_i)
			
		elif item.what_is_it & 010:
			valuable_container.add_child(new_node_instance)
			if new_node_instance.get_index() % valuable_container.columns == 0:
				if flip_v:
					flip_v = false
				else:
					flip_v = true
			new_node_instance.swap_orientation(flip_v)
		elif item.what_is_it & 100:
			quest_item_container.add_child(new_node_instance)
			if new_node_instance.get_index() % quest_item_container.columns == 0:
				if flip_q:
					flip_q = false
				else:
					flip_q = true
			new_node_instance.swap_orientation(flip_q)
		if new_node_instance.get_index() > 9:
			new_node_instance.visible = false

func tab_changed(which_tab):
	if not Global.is_paused:
		return
	for child in range($Container.get_child_count()):
		if which_tab == child:
			$Container.get_child(child).visible = true
		else:
			$Container.get_child(child).visible = false
