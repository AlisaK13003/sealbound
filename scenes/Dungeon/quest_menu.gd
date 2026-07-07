extends Control

@onready var menu_tabs = $Panel/MenuTabs
@onready var quest_selection_tabs = $MenuTabs
@onready var completed_quest_tabs = $Panel/MenuTabs2
@onready var quest_description_container = $Quest_Description_Container
@onready var completed_quest_description_container = $Quest_Description_Container2
@onready var scroll_bar = $VScrollBar

var quest_menu_node = "res://assets/Resources/Pause Menu/Quest Menu/Quest_Menu_Node.tscn"
var quest_description_node = "res://assets/Resources/Pause Menu/Quest Menu/Quest_Overview.tscn"

var container_start_position: Vector2

var active_quest_container: Node
var active_desc_container: Node

var current_item = 0
var current_slot = 0
var scroll_cooldown_timer: float = 0.0
const SCROLL_COOLDOWN_TIME: float = 0.08
var can_scroll: bool = false

func _ready():
	active_quest_container = menu_tabs
	active_desc_container = quest_description_container

	var all_active_quest_names: Array[String] = []
	var completed_quest_names: Array[String] = []
	
	container_start_position = menu_tabs.position
	
	for quest_: quest in GlobalCombatInformation.active_quests:
		all_active_quest_names.append(quest_.quest_name)

	for quest_: quest in GlobalCombatInformation.completed_quests:
		completed_quest_names.append(quest_.quest_name)
	
	completed_quest_tabs._setup(completed_quest_names, quest_menu_node)
	menu_tabs._setup(all_active_quest_names, quest_menu_node)
	quest_selection_tabs._setup(["Active Quests", "Completed Quests"])
	
	for child in range(GlobalCombatInformation.active_quests.size()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.active_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		
		quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.active_quests[child])
	
	for child in range(GlobalCombatInformation.completed_quests.size()):
		completed_quest_tabs.get_child(child)._setup(GlobalCombatInformation.completed_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		
		completed_quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.completed_quests[child])

	GlobalCombatInformation.check_quest_progress.connect(update_quests)
	menu_tabs.selection_changed.connect(tab_changed)
	completed_quest_tabs.selection_changed.connect(tab_changed) 
	quest_selection_tabs.selection_changed.connect(quest_type_type_changed)
	visibility_changed.connect(_reset)
	
	_reset()

func update_quests():
	for child in quest_description_container.get_children():
		quest_description_container.remove_child(child)
		child.queue_free()
	for child in menu_tabs.get_children():
		menu_tabs.remove_child(child)
		child.queue_free()
		
	for child in completed_quest_description_container.get_children():
		completed_quest_description_container.remove_child(child)
		child.queue_free()
	for child in completed_quest_tabs.get_children():
		completed_quest_tabs.remove_child(child)
		child.queue_free()
		
	var all_active_quest_names: Array[String] = []
	var completed_quest_names: Array[String] = []

	for quest_: quest in GlobalCombatInformation.active_quests:
		all_active_quest_names.append(quest_.quest_name)
	
	for quest_: quest in GlobalCombatInformation.completed_quests:
		completed_quest_names.append(quest_.quest_name)
	
	completed_quest_tabs._setup(completed_quest_names, quest_menu_node)
	menu_tabs._setup(all_active_quest_names, quest_menu_node)
		
	for child in range(GlobalCombatInformation.active_quests.size()):
		menu_tabs.get_child(child)._setup(GlobalCombatInformation.active_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		
		quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.active_quests[child])
	
	for child in range(GlobalCombatInformation.completed_quests.size()):
		completed_quest_tabs.get_child(child)._setup(GlobalCombatInformation.completed_quests[child])
		
		var new_description = load(quest_description_node)
		var new_description_instance = new_description.instantiate()
		
		completed_quest_description_container.add_child(new_description_instance)
		new_description_instance._setup(GlobalCombatInformation.completed_quests[child])

	if active_quest_container and active_quest_container.has_method("cycle_input"):
		active_quest_container.cycle_input(null, 0)

func _reset():
	if visible:
		update_quests()
		return
	menu_tabs.cycle_input(null, -1000)
	completed_quest_tabs.cycle_input(null, -1000)
	quest_selection_tabs.cycle_input(null, -10)
	quest_type_type_changed(0) 

func tab_changed(which_tab):
	if not active_desc_container:
		return
	for child in range(active_desc_container.get_child_count()):
		if which_tab == child:
			active_desc_container.get_child(child).visible = true
			current_item = which_tab
		else:
			active_desc_container.get_child(child).visible = false

func quest_type_type_changed(which_tab):
	current_item = 0
	current_slot = 0

	match which_tab:
		0: # Active Quests
			active_quest_container = menu_tabs
			active_desc_container = quest_description_container
			
			quest_description_container.visible = true
			completed_quest_description_container.visible = false
			menu_tabs.visible = true
			completed_quest_tabs.visible = false
		1: # Completed Quests
			active_quest_container = completed_quest_tabs
			active_desc_container = completed_quest_description_container
			
			quest_description_container.visible = false
			completed_quest_description_container.visible = true
			menu_tabs.visible = false
			completed_quest_tabs.visible = true

	menu_tabs.position.y = container_start_position.y
	completed_quest_tabs.position.y = container_start_position.y

	scroll_bar.max_value = max(0, active_quest_container.get_child_count() - 6)
	scroll_bar.value = 0
	
	update_selected_item()

func _process(delta: float):
	if not Global.is_paused:
		return
	if scroll_cooldown_timer > 0.0:
		scroll_cooldown_timer -= delta

func _on_v_scroll_bar_value_changed(value):
	if not active_quest_container or active_quest_container.get_child_count() == 0:
		return
	
	update_selected_item()
	
	var separation = active_quest_container.get_theme_constant("v_separation")
	active_quest_container.position.y = container_start_position.y - ((value * separation) * active_quest_container.scale.y)

func update_selected_item():
	if not active_quest_container:
		return
	for child in active_quest_container.get_children():
		if child.get_index() == current_item:
			child.update_highlight(true)
			tab_changed(child.get_index())
		else:
			child.update_highlight(false)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if not can_scroll:
			return
			
		if scroll_cooldown_timer > 0.0:
			return
			
		if not active_quest_container or active_quest_container.get_child_count() == 0:
			return
			
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_slot = clamp(current_slot - 1, 0, scroll_bar.max_value + 1)
			current_item = clamp(current_item - 1, 0, active_quest_container.get_child_count() - 1)
			scroll_bar.value = current_slot
			scroll_cooldown_timer = SCROLL_COOLDOWN_TIME
			get_viewport().set_input_as_handled()
			update_selected_item()
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_slot = clamp(current_slot + 1, 0, scroll_bar.max_value + 1)
			current_item = clamp(current_item + 1, 0, active_quest_container.get_child_count() - 1)
			scroll_bar.value = current_slot
			scroll_cooldown_timer = SCROLL_COOLDOWN_TIME
			get_viewport().set_input_as_handled()
			update_selected_item()

func _on_area_2d_mouse_entered():
	can_scroll = true

func _on_area_2d_mouse_exited():
	can_scroll = false
