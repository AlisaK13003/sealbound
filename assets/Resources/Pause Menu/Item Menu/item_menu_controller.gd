extends Control

#@onready var item_container = $VBoxContainer
#@onready var party_cards = $Party_Cards
var item_scene = "res://assets/Resources/Pause Menu/Item Menu/Display_item.tscn"
@onready var item_container = $Panel2/Container/GridContainer
@onready var valuable_container = $Panel2/Container/GridContainer2
@onready var quest_item_container = $Panel2/Container/GridContainer3

@onready var menu_tabs = $MenuTabs
@onready var party_tabs = $MenuTabs2

var selected_item = 0

@export var menu_parent : Control
@export var custom_tab_path: String

func _reset():
	item_container.visible = true
	valuable_container.visible = false
	quest_item_container.visible = false
	current_item = 0
	selected_item = null
	$Panel2/Container.position = container_start_position
	update_selected_item()
	GlobalCombatInformation.check_quest_progress

func _fully_reset():
	for child_ in $Panel2/Container.get_children():
		for child__ in child_.get_children():
			child__.queue_free()
	
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
	$VScrollBar.max_value = int($Panel2/Container.get_child(visible_tab).get_child_count()) - 24
	$VScrollBar.value = 0
	update_selected_item()

func _ready():
	party_tabs._setup(GlobalCombatInformation.all_party_slots, custom_tab_path)
	for child in range(party_tabs.get_child_count()):
		party_tabs.get_child(child)._setup(GlobalCombatInformation.all_party_slots[child], child, true)
	
	container_start_position = $Panel2/Container.position
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
			
	for item_menu in $Panel2/Container.get_children():
		for item_ in item_menu.get_children():
			item_.item_clicked.connect(update_selected_item.bind(true))
			
	$VScrollBar.max_value = int($Panel2/Container.get_child(visible_tab).get_child_count()) - 24
	$VScrollBar.value = 0
	update_selected_item()
	tab_changed(0)
	
var visible_tab = 0
func tab_changed(which_tab):
	if not Global.is_paused:
		return
	for child in range($Panel2/Container.get_child_count()):
		if which_tab == child:
			visible_tab = child
			$Panel2/Container.get_child(child).visible = true
			$VScrollBar.max_value = int($Panel2/Container.get_child(visible_tab).get_child_count()) - 24
			$VScrollBar.value = 0
		else:
			$Panel2/Container.get_child(child).visible = false
	$Panel2/Container.position = container_start_position
	$VScrollBar.value = 0
	current_item = 0
	selected_item = null
	update_selected_item()

var can_scroll: bool = false
func _on_area_2d_mouse_entered():
	can_scroll = true

func _on_area_2d_mouse_exited():
	can_scroll = false

@onready var scroll_bar = $VScrollBar

var scroll_cooldown_timer: float = 0.0
const SCROLL_COOLDOWN_TIME: float = 0.04

func _process(delta: float):
	if not Global.is_paused:
		return
	if scroll_cooldown_timer > 0.0:
		scroll_cooldown_timer -= delta
var container_start_position: Vector2
func _on_v_scroll_bar_value_changed(value):
	if $Panel2/Container.get_child_count() == 0:
		return
	if $Panel2/Container.get_child(visible_tab).get_child_count() == 0:
		return
	$Panel2/Container.position.y = container_start_position.y - (value * $Panel2/Container.get_child(0).get_theme_constant("v_separation"))
	update_selected_item()
	
func update_selected_item(instance_id = null, from_click: bool = false):
	if from_click:
		for item_ in $Panel2/Container.get_child(visible_tab).get_children():
			if item_.get_instance_id() == instance_id:
				current_item = item_.get_index()
				break
				
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
			item_.is_selected(true)
		else:
			item_.is_selected(false)
	display_item()

func display_item():
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
	var found_item: Items = null
	for item_ in GlobalCombatInformation.all_held_items:
		if item_.what_is_it & mask:
			count += 1
			if count == current_item:
				found_item = item_
		
	if found_item != null:
		$"Item Description/VBoxContainer/Label".text = found_item.item_name
		$"Item Description/VBoxContainer/Label2".text = found_item.item_description
		$"Item Description/VBoxContainer/TextureRect".texture = found_item.item_sprite
	else:
		$"Item Description/VBoxContainer/Label".text = ""
		$"Item Description/VBoxContainer/Label2".text = ""
		$"Item Description/VBoxContainer/TextureRect".texture = null

var current_slot = 0
var current_item = 0
func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if not can_scroll:
			return
			
		if scroll_cooldown_timer > 0.0:
			return
		var child_count = $Panel2/Container.get_child(visible_tab).get_child_count()
		if child_count == 0:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_slot = clamp(current_slot - 1, 0, scroll_bar.max_value + 1)
			current_item = clamp(current_item - 1, 0, $Panel2/Container.get_child(visible_tab).get_child_count() - 1)
			scroll_bar.value = current_slot
			scroll_cooldown_timer = SCROLL_COOLDOWN_TIME
			get_viewport().set_input_as_handled()
			update_selected_item()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_slot = clamp(current_slot + 1, 0, scroll_bar.max_value + 1)
			current_item = clamp(current_item + 1, 0, $Panel2/Container.get_child(visible_tab).get_child_count() - 1)
			scroll_bar.value = current_slot
			scroll_cooldown_timer = SCROLL_COOLDOWN_TIME
			get_viewport().set_input_as_handled()
			update_selected_item()
