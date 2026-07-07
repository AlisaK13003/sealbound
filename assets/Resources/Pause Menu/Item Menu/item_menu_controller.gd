extends Control

#@onready var item_container = $VBoxContainer
#@onready var party_cards = $Party_Cards
var item_scene = "res://assets/Resources/Pause Menu/Item Menu/Display_item.tscn"
@onready var item_container = $Panel2/Container/GridContainer
@onready var valuable_container = $Panel2/Container/GridContainer2
@onready var quest_item_container = $Panel2/Container/GridContainer3

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

var can_scroll: bool = false
var scroll_cooldown_timer: float = 0.0
const SCROLL_COOLDOWN_TIME: float = 0.04
var is_programmatic_scroll: bool = false


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
				flip_i = not flip_i
			new_node_instance.swap_orientation(flip_i)
			
		elif item.what_is_it & 010:
			valuable_container.add_child(new_node_instance)
			if new_node_instance.get_index() % valuable_container.columns == 0:
				flip_v = not flip_v
			new_node_instance.swap_orientation(flip_v)
			
		elif item.what_is_it & 100:
			quest_item_container.add_child(new_node_instance)
			if new_node_instance.get_index() % quest_item_container.columns == 0:
				flip_q = not flip_q
			new_node_instance.swap_orientation(flip_q)
			
	for item_menu in $Panel2/Container.get_children():
		for item_ in item_menu.get_children():
			item_.item_clicked.connect(update_selected_item.bind(true))
			
	current_item = 0
	_update_scroll_for_selection()
	update_selected_item()
	tab_changed(0)


func _reset():
	item_container.visible = true
	valuable_container.visible = false
	quest_item_container.visible = false
	current_item = 0
	selected_item = null
	$Panel2/Container.position = container_start_position
	_update_scroll_for_selection()
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
				flip_i = not flip_i
			new_node_instance.swap_orientation(flip_i)
			
		elif item.what_is_it & 010:
			valuable_container.add_child(new_node_instance)
			if new_node_instance.get_index() % valuable_container.columns == 0:
				flip_v = not flip_v
			new_node_instance.swap_orientation(flip_v)
			
		elif item.what_is_it & 100:
			quest_item_container.add_child(new_node_instance)
			if new_node_instance.get_index() % quest_item_container.columns == 0:
				flip_q = not flip_q
			new_node_instance.swap_orientation(flip_q)
			
	for item_menu in $Panel2/Container.get_children():
		for item_ in item_menu.get_children():
			if not item_.item_clicked.is_connected(update_selected_item):
				item_.item_clicked.connect(update_selected_item.bind(true))
				
	current_item = 0
	_update_scroll_for_selection()
	update_selected_item()


func tab_changed(which_tab):
	if not Global.is_paused:
		return
	for child in range($Panel2/Container.get_child_count()):
		if which_tab == child:
			visible_tab = child
			$Panel2/Container.get_child(child).visible = true
		else:
			$Panel2/Container.get_child(child).visible = false
			
	$Panel2/Container.position = container_start_position
	current_item = 0
	selected_item = null
	_update_scroll_for_selection()
	update_selected_item()


func _on_area_2d_mouse_entered():
	can_scroll = true


func _on_area_2d_mouse_exited():
	can_scroll = false


func _process(delta: float):
	if not Global.is_paused:
		return
	if scroll_cooldown_timer > 0.0:
		scroll_cooldown_timer -= delta


# Computes where the scrollbar should be based on the actively selected item
func _update_scroll_for_selection():
	var active_container = $Panel2/Container.get_child(visible_tab)
	var child_count = active_container.get_child_count()
	if child_count == 0:
		return
		
	# We MUST use `display_how_many_items` for the math because the list's positional offset 
	# scales based on individual item indexing, which evaluates to a limit of 15 mechanically.
	var mechanical_window = display_how_many_items
	var middle_index = mechanical_window / 2
	
	var max_scroll = max(0, child_count - mechanical_window)
	scroll_bar.max_value = max_scroll
	
	# Calculates offset so the scroll starts tracking only once passed the middle of the window
	var target_scroll = current_item - middle_index
	target_scroll = clamp(target_scroll, 0, max_scroll)
	
	# Setting value will trigger `_on_v_scroll_bar_value_changed`. 
	# The flag prevents the manual bounds-check from overriding our targeted item.
	is_programmatic_scroll = true
	scroll_bar.value = target_scroll
	is_programmatic_scroll = false


func _on_v_scroll_bar_value_changed(value):
	if $Panel2/Container.get_child_count() == 0:
		return
	var active_container = $Panel2/Container.get_child(visible_tab)
	if active_container.get_child_count() == 0:
		return
		
	# If the user drags the scrollbar directly, clamp their selection to stay in the mechanical bounds
	if not is_programmatic_scroll:
		var top_visible = int(value)
		var bottom_visible = top_visible + display_how_many_items - 1
		
		if current_item < top_visible:
			current_item = top_visible
		elif current_item > bottom_visible:
			current_item = bottom_visible
			
	$Panel2/Container.position.y = container_start_position.y - (value * active_container.get_theme_constant("v_separation"))
	update_selected_item()


func update_selected_item(instance_id = null, from_click: bool = false):
	if from_click:
		var active_container = $Panel2/Container.get_child(visible_tab)
		for item_ in active_container.get_children():
			if item_.get_instance_id() == instance_id:
				current_item = item_.get_index()
				break
		# Scroll to keep clicked item properly centered
		_update_scroll_for_selection()
				
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


func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if not can_scroll:
			return
			
		if scroll_cooldown_timer > 0.0:
			return
			
		var active_container = $Panel2/Container.get_child(visible_tab)
		var child_count = active_container.get_child_count()
		if child_count == 0:
			return
			
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_item = clamp(current_item - 1, 0, child_count - 1)
			scroll_cooldown_timer = SCROLL_COOLDOWN_TIME
			get_viewport().set_input_as_handled()
			_update_scroll_for_selection()
			update_selected_item()
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_item = clamp(current_item + 1, 0, child_count - 1)
			scroll_cooldown_timer = SCROLL_COOLDOWN_TIME
			get_viewport().set_input_as_handled()
			_update_scroll_for_selection()
			update_selected_item()
